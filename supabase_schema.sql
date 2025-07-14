-- Supabase Schema for SubTrackr App

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency_code TEXT NOT NULL DEFAULT 'USD',
    billing_cycle TEXT NOT NULL,
    next_billing_date TIMESTAMP WITH TIME ZONE NOT NULL,
    category TEXT,
    logo_url TEXT,
    description TEXT,
    website TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create price_changes table
CREATE TABLE IF NOT EXISTS price_changes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
    old_price DECIMAL(10,2) NOT NULL,
    new_price DECIMAL(10,2) NOT NULL,
    change_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create currency rates table for proper currency conversion
CREATE TABLE IF NOT EXISTS currency_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    currency_code TEXT NOT NULL UNIQUE,
    usd_rate DECIMAL(10,6) NOT NULL, -- How many USD = 1 unit of this currency
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE currency_rates ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for subscriptions
CREATE POLICY "Users can view own subscriptions" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions" ON subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions" ON subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own subscriptions" ON subscriptions
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for price_changes
CREATE POLICY "Users can view own price changes" ON price_changes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM subscriptions 
            WHERE subscriptions.id = price_changes.subscription_id 
            AND subscriptions.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own price changes" ON price_changes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM subscriptions 
            WHERE subscriptions.id = price_changes.subscription_id 
            AND subscriptions.user_id = auth.uid()
        )
    );

-- Currency rates are read-only for all authenticated users
CREATE POLICY "Authenticated users can view currency rates" ON currency_rates
    FOR SELECT USING (auth.role() = 'authenticated');

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_next_billing_date ON subscriptions(next_billing_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_currency_code ON subscriptions(currency_code);
CREATE INDEX IF NOT EXISTS idx_price_changes_subscription_id ON price_changes(subscription_id);
CREATE INDEX IF NOT EXISTS idx_currency_rates_code ON currency_rates(currency_code);

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for subscriptions
CREATE TRIGGER update_subscriptions_updated_at
    BEFORE UPDATE ON subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create function to delete user and all associated data
CREATE OR REPLACE FUNCTION delete_user()
RETURNS json AS $$
DECLARE
    user_id_to_delete uuid;
    subscription_count integer;
BEGIN
    -- Get the current user ID
    user_id_to_delete := auth.uid();
    
    -- Check if user exists
    IF user_id_to_delete IS NULL THEN
        RETURN json_build_object('success', false, 'message', 'No authenticated user');
    END IF;
    
    -- Count subscriptions before deletion
    SELECT COUNT(*) INTO subscription_count 
    FROM public.subscriptions 
    WHERE user_id = user_id_to_delete;
    
    -- Delete all subscriptions for this user (will cascade to price_changes)
    DELETE FROM public.subscriptions WHERE user_id = user_id_to_delete;
    
    -- Try to invalidate all sessions for this user (may fail due to permissions)
    -- This is why we also handle sign-out on the client side
    BEGIN
        DELETE FROM auth.sessions WHERE user_id = user_id_to_delete;
        DELETE FROM auth.refresh_tokens WHERE user_id = user_id_to_delete;
    EXCEPTION
        WHEN OTHERS THEN
            -- Sessions deletion failed, but continue with user deletion
            -- Client will handle sign-out
            NULL;
    END;
    
    -- Delete user from auth.users
    DELETE FROM auth.users WHERE id = user_id_to_delete;
    
    -- Return success
    RETURN json_build_object(
        'success', true, 
        'message', 'User deleted successfully',
        'subscriptions_deleted', subscription_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION delete_user() TO authenticated;

-- Insert default currency rates (these should be updated regularly)
INSERT INTO currency_rates (currency_code, usd_rate) VALUES 
    ('USD', 1.0),
    ('EUR', 1.08),
    ('GBP', 1.26),
    ('CAD', 0.74),
    ('AUD', 0.67),
    ('JPY', 0.0067),
    ('CHF', 1.11),
    ('CNY', 0.14),
    ('INR', 0.012),
    ('BRL', 0.20)
ON CONFLICT (currency_code) DO NOTHING;

-- Create function to convert currency to USD
CREATE OR REPLACE FUNCTION convert_to_usd(amount DECIMAL, currency_code TEXT)
RETURNS DECIMAL AS $$
DECLARE
    rate DECIMAL;
BEGIN
    -- Get the USD conversion rate for the currency
    SELECT usd_rate INTO rate 
    FROM currency_rates 
    WHERE currency_rates.currency_code = convert_to_usd.currency_code;
    
    -- If currency not found, assume 1:1 with USD
    IF rate IS NULL THEN
        rate := 1.0;
    END IF;
    
    -- Convert to USD
    RETURN amount * rate;
END;
$$ LANGUAGE plpgsql;

-- Create currency-aware analytics view (using correct column names)
CREATE OR REPLACE VIEW subscription_analytics AS
SELECT 
    user_id,
    -- Total subscriptions count
    COUNT(*) as total_subscriptions,
    
    -- Per-currency totals (preserves original currencies)
    jsonb_object_agg(
        currency_code, 
        jsonb_build_object(
            'count', currency_count,
            'total_amount', currency_total,
            'average_amount', ROUND(currency_total / currency_count, 2)
        )
    ) as by_currency,
    
    -- USD-converted totals (for meaningful comparison)
    ROUND(SUM(convert_to_usd(amount, currency_code)), 2) as total_monthly_cost_usd,
    ROUND(AVG(convert_to_usd(amount, currency_code)), 2) as average_subscription_cost_usd,
    
    -- Most common currency for this user
    (SELECT currency_code 
     FROM subscriptions s2 
     WHERE s2.user_id = s.user_id AND s2.status = 'active'
     GROUP BY currency_code 
     ORDER BY COUNT(*) DESC 
     LIMIT 1) as primary_currency

FROM subscriptions s
JOIN (
    -- Subquery to get per-currency aggregates
    SELECT 
        user_id,
        currency_code,
        COUNT(*) as currency_count,
        SUM(amount) as currency_total
    FROM subscriptions 
    WHERE status = 'active'
    GROUP BY user_id, currency_code
) currency_stats ON s.user_id = currency_stats.user_id AND s.currency_code = currency_stats.currency_code
WHERE s.status = 'active'
GROUP BY s.user_id;

-- Create a simplified view for dashboard display
CREATE OR REPLACE VIEW user_subscription_summary AS
SELECT 
    user_id,
    total_subscriptions,
    primary_currency,
    total_monthly_cost_usd,
    average_subscription_cost_usd,
    by_currency
FROM subscription_analytics;

-- Grant permissions for the views
GRANT SELECT ON subscription_analytics TO authenticated;
GRANT SELECT ON user_subscription_summary TO authenticated;

-- Create RLS policies for the views
CREATE POLICY "Users can view own analytics" ON subscription_analytics
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own summary" ON user_subscription_summary  
    FOR SELECT USING (auth.uid() = user_id); 