# Data Stream Predictive Analytics Smart Contract

A decentralized predictive analytics platform with machine learning integration and reputation-based governance built on the Stacks blockchain using Clarity.

## Overview

This smart contract enables data providers to submit predictions, register machine learning models, and participate in a community-driven validation system. The platform maintains on-chain reputation scores to ensure data quality and reward accurate predictions.

## Features

### 🎯 **Predictive Analytics**
- Submit data streams with predictions and confidence scores
- Categorized data organization
- Hash-based data integrity verification
- Timestamp tracking for all submissions

### 🤖 **Machine Learning Integration**
- Register ML models with accuracy tracking
- Model usage statistics and performance metrics
- Creator ownership and model versioning

### ⭐ **Reputation System**
- Dynamic reputation scoring based on prediction accuracy
- Community-driven validation mechanism
- Minimum reputation thresholds for participation
- Automatic rewards and penalties

### 🔒 **Security & Governance**
- Multi-level authorization controls
- Owner-managed penalty system
- Input validation and error handling
- Activity status management

## Contract Architecture

### Data Structures

#### Data Providers
```clarity
{
    reputation-score: uint,
    total-submissions: uint,
    correct-predictions: uint,
    last-submission: uint,
    is-active: bool
}
```

#### Data Streams
```clarity
{
    provider: principal,
    data-hash: (buff 32),
    prediction-value: uint,
    confidence-score: uint,
    timestamp: uint,
    category: (string-ascii 50),
    is-validated: bool,
    validation-score: uint
}
```

#### ML Models
```clarity
{
    model-hash: (buff 32),
    accuracy: uint,
    creator: principal,
    creation-time: uint,
    usage-count: uint
}
```

## Getting Started

### Prerequisites
- [Clarinet CLI](https://docs.hiro.so/stacks/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for testing

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd data-stream-analytics
```

2. Check contract syntax:
```bash
clarinet check
```

3. Run tests:
```bash
npm install
npm test
```

### Deployment

1. Configure your deployment settings in `Clarinet.toml`
2. Deploy to testnet:
```bash
clarinet publish --testnet
```

## Usage Guide

### 1. Initialize Contract (Owner Only)
```clarity
(contract-call? .data-stream initialize-contract)
```

### 2. Register as Data Provider
```clarity
(contract-call? .data-stream register-provider)
```

### 3. Submit Prediction
```clarity
(contract-call? .data-stream submit-data-stream
    0x1234...  ;; data-hash
    u85        ;; prediction-value
    u90        ;; confidence-score
    "weather"  ;; category
)
```

### 4. Register ML Model
```clarity
(contract-call? .data-stream register-ml-model
    0xabcd...  ;; model-hash
)
```

### 5. Validate Prediction
```clarity
(contract-call? .data-stream validate-prediction
    u1     ;; stream-id
    true   ;; is-correct
)
```

### 6. Check Provider Information
```clarity
(contract-call? .data-stream get-provider-info 'SP1234...)
```

## API Reference

### Public Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `initialize-contract` | Initialize the contract (owner only) | None | `(response bool uint)` |
| `register-provider` | Register as a data provider | None | `(response bool uint)` |
| `submit-data-stream` | Submit prediction data | `data-hash`, `prediction-value`, `confidence-score`, `category` | `(response uint uint)` |
| `register-ml-model` | Register a machine learning model | `model-hash` | `(response uint uint)` |
| `validate-prediction` | Validate a prediction | `stream-id`, `is-correct` | `(response bool uint)` |
| `update-model-accuracy` | Update ML model accuracy | `model-id`, `new-accuracy` | `(response bool uint)` |
| `penalize-provider` | Penalize provider (owner only) | `provider`, `penalty-amount` | `(response bool uint)` |

### Read-Only Functions

| Function | Description | Parameters | Returns |
|----------|-------------|------------|---------|
| `get-provider-info` | Get provider details | `provider` | `(optional {...})` |
| `get-stream-info` | Get data stream details | `stream-id` | `(optional {...})` |
| `get-model-info` | Get ML model details | `model-id` | `(optional {...})` |
| `get-provider-success-rate` | Calculate success rate | `provider` | `(optional uint)` |
| `get-provider-reputation` | Get reputation score | `provider` | `(optional uint)` |
| `can-submit-data` | Check submission eligibility | `provider` | `bool` |

## Reputation System

### Scoring Mechanism
- **Initial Score**: 100 points for new providers
- **Correct Prediction**: +5 points
- **Incorrect Prediction**: -5 points
- **Validation Participation**: +2 points
- **Minimum for Submissions**: 50 points
- **Minimum for Validation**: 75 points

### Activity Status
Providers with reputation below 25 points are automatically deactivated and cannot submit data until their reputation is restored.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | `ERR-UNAUTHORIZED` | Unauthorized access attempt |
| u101 | `ERR-NOT-FOUND` | Resource not found |
| u102 | `ERR-INVALID-DATA` | Invalid data provided |
| u103 | `ERR-INSUFFICIENT-REPUTATION` | Reputation too low |
| u104 | `ERR-ALREADY-EXISTS` | Resource already exists |

## Best Practices

### For Data Providers
1. **Quality First**: Focus on accuracy over quantity
2. **Consistent Participation**: Regular submissions improve reputation
3. **Honest Confidence Scores**: Provide realistic confidence assessments
4. **Category Consistency**: Use consistent category naming

### For Validators
1. **Fair Assessment**: Validate predictions objectively
2. **Timely Validation**: Validate predictions promptly
3. **Reputation Management**: Maintain high reputation for validation rights

### For ML Model Creators
1. **Accurate Metrics**: Report honest accuracy scores
2. **Regular Updates**: Keep model performance metrics current
3. **Documentation**: Use descriptive model hashes

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents malicious data
- Reputation thresholds prevent spam
- Owner controls for emergency situations
- Hash-based data integrity verification

## Testing

Run the test suite to verify contract functionality:

```bash
# Run all tests
npm test

# Run specific test file
npm test tests/data-stream_test.ts
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions and support:
- Create an issue in the repository
- Join our Discord community
- Check the documentation wiki

## Roadmap

- [ ] Advanced ML model integration
- [ ] Multi-signature validation
- [ ] Staking mechanisms
- [ ] Cross-chain compatibility
- [ ] Advanced analytics dashboard
- [ ] Mobile app integration

## Changelog

### v1.0.0
- Initial release
- Basic predictive analytics functionality
- Reputation system implementation
- ML model registration
- Community validation system