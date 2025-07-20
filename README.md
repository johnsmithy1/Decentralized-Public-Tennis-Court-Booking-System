# Decentralized Public Tennis Court Booking System

A comprehensive blockchain-based system for managing public tennis court reservations, maintenance, lighting, tournaments, and fee collection using Clarity smart contracts.

## System Overview

This system consists of five interconnected smart contracts that manage all aspects of public tennis court operations:

### 1. Court Reservation Contract (`court-reservation.clar`)
- Manages hourly court bookings and cancellations
- Tracks court availability and reservation status
- Handles booking conflicts and time slot management
- Supports multiple courts with individual scheduling

### 2. Maintenance Scheduling Contract (`maintenance-scheduling.clar`)
- Coordinates court resurfacing and net repairs
- Schedules preventive maintenance windows
- Tracks maintenance history and completion status
- Manages maintenance crew assignments

### 3. Lighting Control Contract (`lighting-control.clar`)
- Manages court illumination for evening play
- Controls automated lighting schedules
- Tracks energy usage and costs
- Handles manual lighting overrides

### 4. Tournament Organization Contract (`tournament-organization.clar`)
- Schedules community tennis competitions
- Manages tournament registration and brackets
- Coordinates court allocations for events
- Tracks tournament results and statistics

### 5. Fee Collection Contract (`fee-collection.clar`)
- Processes court rental payments
- Manages annual pass subscriptions
- Handles refunds and payment disputes
- Tracks revenue and financial reporting

## Features

### Court Reservation System
- **Hourly Bookings**: Reserve courts for 1-4 hour slots
- **Advance Booking**: Reserve up to 7 days in advance
- **Cancellation Policy**: Cancel up to 2 hours before booking
- **Multi-Court Support**: Manage up to 8 courts simultaneously
- **Conflict Prevention**: Automatic double-booking prevention

### Maintenance Management
- **Scheduled Maintenance**: Regular resurfacing and repairs
- **Emergency Repairs**: Immediate maintenance requests
- **Court Status Tracking**: Available, under maintenance, or closed
- **Maintenance History**: Complete audit trail of all work

### Smart Lighting
- **Automated Schedules**: Lights activate based on bookings
- **Energy Efficiency**: Automatic shutoff after sessions
- **Manual Override**: Emergency lighting controls
- **Usage Tracking**: Monitor electricity consumption

### Tournament Support
- **Event Scheduling**: Plan tournaments around regular bookings
- **Registration System**: Player signup and bracket management
- **Court Allocation**: Automatic court assignment for matches
- **Results Tracking**: Tournament outcomes and statistics

### Payment Processing
- **Flexible Pricing**: Hourly rates and annual passes
- **Secure Payments**: Blockchain-based transaction processing
- **Refund System**: Automated refunds for valid cancellations
- **Revenue Tracking**: Comprehensive financial reporting

## Technical Architecture

### Data Structures
- **Court Information**: ID, status, location, surface type
- **Reservations**: User, court, time slot, payment status
- **Maintenance Records**: Type, date, crew, completion status
- **Lighting Schedules**: Court, start/end times, energy usage
- **Tournament Data**: Event details, participants, results

### Security Features
- **Access Control**: Role-based permissions for different operations
- **Input Validation**: Comprehensive parameter checking
- **State Management**: Consistent contract state across operations
- **Error Handling**: Detailed error codes and messages

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Basic understanding of Clarity smart contracts

### Installation
1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage Examples

#### Making a Court Reservation
\`\`\`clarity
(contract-call? .court-reservation book-court u1 u1640995200 u2)
\`\`\`

#### Scheduling Maintenance
\`\`\`clarity
(contract-call? .maintenance-scheduling schedule-maintenance u1 "resurfacing" u1640995200)
\`\`\`

#### Controlling Lighting
\`\`\`clarity
(contract-call? .lighting-control activate-lights u1 u1640995200 u1641001600)
\`\`\`

## Testing

The system includes comprehensive tests for all contracts:
- Unit tests for individual functions
- Integration tests for contract interactions
- Edge case testing for error conditions
- Performance tests for high-load scenarios

Run tests with: `npm test`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details
