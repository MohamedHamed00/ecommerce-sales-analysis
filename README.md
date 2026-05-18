# E-Commerce Sales & Customer Behavior Analysis

## Project Overview
Analysis of an e-commerce dataset containing 25,000 orders, 8,000 customers, and 140 products. The goal was to uncover insights about product performance, revenue trends, and customer behavior using PostgreSQL.

## Tools Used
- **Excel & Power Query** — Data cleaning and preparation
- **PostgreSQL** — Data analysis and querying

## Dataset
- `customers.csv` — 8,000 customer records with demographics and behavior metrics
- `orders.csv` — 25,000 transactions from 2020 to 2026
- `monthly_revenue.csv` — Aggregated monthly revenue data
- `product_summary.csv` — Product-level performance summary

## Key Findings

### Part 1: Product & Revenue Analysis
- Electronics is the top category by both revenue and units sold across most countries
- Revenue has grown consistently year over year from 2020 to 2025
- Q2 was the strongest quarter for most years, likely driven by seasonal demand
- Travel & Luggage has the highest return rate when measured as a percentage — not Electronics as raw numbers suggest

### Part 2: Customer Behavior Analysis
- 64% of orders are from repeat customers, indicating strong loyalty overall
- Middle Aged customers (35-49) are the largest buying segment
- Gold tier members have the highest churn rate — suggesting the tier may not deliver enough value
- Young Adults (18-24) churn the most by age group
- Newsletter subscription shows no significant impact on order frequency
- December drives the highest new customer acquisition — driven by holiday demand, not discounts
