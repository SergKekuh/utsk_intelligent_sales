# UTSK Intelligent Sales - C++ Application

Version: 1.0.0
Language: C++17
License: Proprietary

## Description

UTSK Intelligent Sales is a console and GUI application for working with 
the bd_intelligent_sales PostgreSQL database.

Features:
- RFM analytics - automatic client segmentation
- Activity direction detection - revenue-based voting
- Smart recommendations - personalized product suggestions
- ML self-learning - product scoring based on manager actions
- Dashboards - KPI and client status visualization

## Quick Start

### Clone repository
git clone https://github.com/your-username/utsk_intelligent_sales.git
cd utsk_intelligent_sales

### Install dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y cmake g++ make libpqxx-dev nlohmann-json3-dev

### Configure database
cp config/db_config.example.json config/db_config.json
nano config/db_config.json

### Build (AFTER implementing main_console.cpp)
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel $(nproc)

### Run console version
./build/utsk_console

## Project Structure

utsk_intelligent_sales/
├── config/          # Configuration files
├── include/         # Header files (.hpp)
├── src/             # Source files (.cpp)
├── tests/           # Unit and integration tests
├── resources/       # Icons, styles, UI forms
├── docs/            # Documentation
├── docker/          # Docker containerization
├── .github/         # GitHub Actions CI/CD
└── cmake/           # CMake modules

## Dependencies

| Library | Purpose | Version |
|---------|---------|---------|
| C++ | Programming language | 17+ |
| libpqxx | PostgreSQL connector | 7.x |
| nlohmann_json | JSON parsing | 3.x |
| Qt6 (opt.) | GUI interface | 6.4+ |
| Google Test (opt.) | Testing | 1.12+ |

## License

Proprietary. All rights reserved. Copyright UTSK, 2026.
