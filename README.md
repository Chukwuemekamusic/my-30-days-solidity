# 30-Day Solidity Challenge 🚀

Welcome to my 30-Day Solidity Challenge repository! This project documents my journey through the intensive learning calendar provided by [web3compass](https://www.web3compass.xyz/challenge-calendar). Each day, I tackle a new concept, pattern, or real-world problem in Solidity, documenting my code and key learnings along the way.

## Challenge Overview

This repository is structured by day, with each folder containing the source code, tests, and scripts for that day's challenge. The goal is to build a strong, practical foundation in smart contract development by consistently coding and solving problems.

### Challenge Calendar & Progress

| Day | Topic                          | Status    | Folder                      |
| --- | ------------------------------ | --------- | --------------------------- |
| 1-7 | Solidity Fundamentals & Basics | Completed | `src/Day_01` - `src/Day_07` |
| 8   | Gas Optimization: Tip Jar      | Completed | `src/Day_08`                |
| 9   | Libraries & Smart Calculator   | Completed | `src/Day_09`                |
| 10  | On-chain Activity Tracker      | Completed | `src/Day_10`                |
| 11  | Secure Vault with Ownable      | Completed | `src/Day_11`                |
| 12  | ERC20: My First Token          | Completed | `src/Day_12`                |
| 13  | Token Pre-sale Contract        | Completed | `src/Day_13`                |
| 14  | Factory Pattern: Vault Manager | Completed | `src/Day_14`                |
| 15  | Gas Saver Contract             | Completed | `src/Day_15`                |
| ... | ...                            | ...       | ...                         |

_(This table will be updated as I progress through the challenge.)_

## How to Use This Repository

You can use this repository to follow my progress, review my solutions, or even try the challenges yourself. All projects are built using the [Foundry](https://github.com/foundry-rs/foundry) framework.

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Installation & Setup

1.  **Clone the repository:**

    ```sh
    git clone git@github.com:Chukwuemekamusic/my-30-days-solidity.git
    cd my-30days-solidity
    ```

2.  **Install dependencies:**
    ```sh
    forge install
    ```

### Running Tests

To run the tests for a specific day's contract, use the `forge test` command with the `--match-path` flag. For example, to test the Day 14 `VaultManager`:

```sh
forge test --match-path test/Day_14/VaultManager.t.sol
```

To run all tests in the repository:

```sh
forge test -vvv
```

## Key Learnings & Concepts Covered

Throughout this challenge, I have explored and implemented various core concepts, including:

- **Solidity Fundamentals:** State variables, functions, modifiers, events, and error handling.
- **Gas Optimization:** Techniques to write efficient, low-cost smart contracts.
- **Design Patterns:** Factory Pattern, Upgradable Contracts, and more.
- **Security Best Practices:** Identifying and mitigating common vulnerabilities like re-entrancy.
- **Advanced Testing:** In-depth testing strategies using Foundry.
- **DeFi Applications:** Building foundational DeFi primitives like staking and swapping contracts.
- **Token Standards:** Implementing ERC20, ERC721, and other common standards.

## Acknowledgments

A huge thank you to **[web3compass](https://www.web3compass.xyz/challenge-calendar)** for creating and sharing this excellent 30-day learning calendar. It's an invaluable resource for anyone looking to level up their Solidity skills.
