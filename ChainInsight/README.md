# ChainInsight

A blockchain explorer and analytics smart contract that provides comprehensive on-chain data indexing, transaction tracking, and network statistics.

## Overview

ChainInsight serves as the backend infrastructure for blockchain explorers and analytics platforms. It indexes transactions, tracks address activities, and maintains network-wide statistics to enable rich data visualization and analysis.

## Key Features

- **Transaction Indexing**: Complete transaction data storage with metadata and type classification
- **Address Analytics**: Track sending/receiving patterns, activity scores, and transaction history
- **Block Statistics**: Per-block metrics including transaction counts, volumes, and fees
- **Daily Metrics**: Aggregated daily network activity and trend analysis
- **Network Statistics**: Global counters for total transactions, volume, and unique addresses
- **Activity Scoring**: Calculate address reputation based on transaction patterns

## Core Functions

### Data Indexing
- `index-transaction(tx-hash, sender, recipient, amount, tx-type, fee-paid)` - Index new transaction data

### Query Functions
- `get-transaction-info(tx-hash)` - Retrieve complete transaction details
- `get-address-stats(address)` - Get address activity statistics
- `get-block-stats(block-number)` - Fetch block-level metrics
- `get-daily-metrics(date)` - Access daily aggregated data
- `get-network-stats()` - View global network statistics
- `calculate-address-score(address)` - Compute address activity score

### Analytics
- `get-tx-type-stats(tx-type)` - Transaction type breakdown
- `search-transactions-by-address(address, limit)` - Address transaction history

## Use Cases

- **Block Explorers**: Power transaction lookup and address history interfaces
- **Analytics Dashboards**: Network usage trends and activity monitoring
- **Compliance Tools**: Address tracking and transaction analysis
- **Research Platforms**: Academic and market research data source

## Data Structure

The contract maintains comprehensive statistics across multiple dimensions:
- Individual transaction records with full metadata
- Address-level aggregations (sent/received/count/timing)
- Block-level summaries (volume/fees/transaction counts)
- Daily network metrics for trend analysis
- Transaction type categorization and volumes

Built for applications requiring deep blockchain data analysis and real-time network insights.