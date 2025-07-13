# Supabase Setup Guide

This guide will walk you through setting up Supabase for the SubTrackr app.

## Prerequisites

- Supabase account
- Project created in Supabase dashboard

## Database Setup

1. Create a new Supabase project
2. Run the schema from supabase_schema.sql
3. Configure RLS policies
4. Set up authentication

## Configuration

Update the following in lib/core/config/supabase_config.dart:
- supabaseUrl: Your project URL
- supabaseAnonKey: Your anonymous key

## Authentication

The app supports:
- Email/password authentication
- Google Sign-In (via Supabase)
- Guest mode with local storage

## Database Schema

The schema includes:
- subscriptions table
- price_changes table
- RLS policies for user data isolation

## Testing

Test both authenticated and guest modes to ensure proper functionality. 