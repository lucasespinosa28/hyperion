# **Project Hyperion: A Technical Blueprint for a Decentralized Perpetuals Exchange**

## 

## **Introduction**

The proliferation of Decentralized Finance (DeFi) has irrevocably altered the landscape of financial services, moving from simple token swaps to increasingly sophisticated instruments that mirror and innovate upon those found in traditional finance (TradFi). Among the most compelling of these are decentralized derivatives, particularly leveraged trading platforms. These platforms empower users to amplify their market exposure, speculate on price movements, and hedge existing positions with a degree of transparency and self-custody previously unattainable. This report provides a comprehensive technical blueprint for the design and implementation of "Project Hyperion," a decentralized application (dApp) for leveraged trading on the Ethereum blockchain.

The core mandate for Project Hyperion is to create a system where a user can deposit collateral, such as 1,000 USDC, and open a long or short position with up to 10x leverage. The architecture will be predicated on a peer-to-pool model, where traders execute positions against a shared liquidity pool that serves as the universal counterparty. This model contrasts with traditional order book systems and offers distinct advantages in liquidity efficiency and user experience. To ensure solvency and manage risk, the system will employ an automated liquidation engine triggered by real-world asset prices, which will be sourced via a decentralized oracle network.

This document serves as an exhaustive guide for the technical founder, project lead, or development team tasked with building such a platform. It is structured to build knowledge from the ground up, starting with the foundational financial mechanics of leverage and perpetual contracts, moving through a detailed architectural design, delving into the specifics of smart contract implementation, and culminating in a robust framework for security and deployment. The analysis draws upon the established architectures of leading DeFi protocols such as GMX, dYdX, and Synthetix, providing a comparative context for the design decisions made herein.1 The ultimate goal is to furnish a complete, actionable, and expert-level plan that not only details

*how* to build the system but, more critically, explains the financial and technical *why* behind each architectural choice.

---

## **Part I: Foundational Mechanics of Decentralized Leveraged Trading**

Before a single line of code is written, it is imperative to establish a deep and nuanced understanding of the financial primitives that govern leveraged trading. These concepts—leverage, margin, perpetual futures, and liquidation—are not merely features to be implemented; they are interconnected components of a delicate economic engine. Misunderstanding their interplay can lead to catastrophic protocol failure. This section deconstructs these core mechanics, providing the theoretical bedrock upon which Project Hyperion will be built.

### **Chapter 1: The Core Primitives: Leverage, Margin, and Collateral**

At the heart of any derivatives platform are the fundamental tools that allow traders to manage positions larger than their own capital. These tools, while powerful, introduce commensurate risks that the protocol must be designed to mitigate.

#### **Understanding Leverage, Collateral, and Margin**

**Leverage** is the practice of using borrowed funds to increase the size of a trading position.4 It acts as a multiplier on a trader's capital, amplifying their exposure to an asset's price movements. For instance, with a 1,000 USDC deposit, a trader using 10x leverage can control a position with a notional value of 10,000 USDC.6 This amplification is a double-edged sword: a 5% favorable price movement on the underlying asset would result in a 50% profit on the trader's initial capital, but a 5% adverse movement would result in a 50% loss.4 The primary allure of leverage is the potential for magnified returns and enhanced capital efficiency, allowing traders to take meaningful positions without committing large amounts of capital.7

The ability to use leverage is predicated on the concepts of **collateral** and **margin**. These terms are often used interchangeably but have distinct meanings.5

* **Collateral** refers to the assets a trader deposits into the protocol to secure the borrowed funds. In the context of Project Hyperion, a user would deposit an ERC-20 token like USDC, which then serves as a guarantee against potential losses on their leveraged position.6 The protocol holds this collateral in a secure smart contract vault.  
* **Margin** is the amount of equity a trader has in their position, representing the value of their collateral relative to their potential losses. The **initial margin** is the amount of collateral required to open the position in the first place.8 For a simple isolated position, the initial margin is the total collateral deposited for that trade. As the trade incurs unrealized profits or losses, the margin value fluctuates. If losses erode the margin to a critical level, the position is at risk of liquidation.6

#### **Margin Modes: The Critical Choice of Isolated Margin**

Leveraged trading platforms typically offer two modes for managing margin: isolated margin and cross margin.4 The choice between them has significant implications for both the user's risk profile and the protocol's architectural complexity.

* **Cross Margin:** In this mode, a trader's entire account balance is used as collateral for all of their open positions. A profit from one position can be used to cover losses on another, effectively spreading the risk across the entire portfolio. This reduces the likelihood of any single position being liquidated quickly, but it also means that a single catastrophic trade can drain the user's entire account balance.4  
* **Isolated Margin:** This mode confines the risk of a position to a specific amount of collateral allocated to it. If a position is liquidated, the trader only loses the margin assigned to that specific trade; the rest of their funds held by the protocol are unaffected.4 This is ideal for speculative trades or for beginners who wish to practice disciplined risk management by limiting the funds at stake for any given idea.4

For Project Hyperion, the user's specified flow—"deposit $1000 and go long or short"—naturally aligns with the **isolated margin** model. Each trade is a discrete, self-contained event. This architectural decision simplifies the core smart contract logic by removing the need to track and manage a unified account balance across multiple positions. However, this simplicity introduces a subtle but critical dynamic concerning the ongoing costs of maintaining a position. In an isolated margin system, the position's margin must single-handedly absorb not only price-based losses but also periodic fees like the funding rate. A sustained, unfavorable funding rate can steadily erode an isolated position's margin, pushing it closer to liquidation even if the asset's price remains stable. This "time decay" risk becomes a first-class parameter for every individual position, a factor that must be explicitly calculated by the smart contracts and clearly communicated to the user through the frontend interface.

#### **Long and Short Positions in a Peer-to-Pool Context**

Leverage trading allows traders to profit from both rising and falling markets through long and short positions.4

* **Going Long:** A trader opens a long position when they expect the price of an asset to increase.11 In the peer-to-pool model of Project Hyperion, when a user goes long on ETH with USDC collateral, they are effectively borrowing additional USDC from the liquidity pool to purchase a larger amount of ETH at the current price. Their profit is the difference between the selling price when they close the position and their entry price.  
* **Going Short:** A trader opens a short position when they expect the price of an asset to decrease.12 To go short on ETH, the trader borrows ETH from the liquidity pool and immediately sells it for a stablecoin like USDC at the current price. To close the position, they must buy back the same amount of ETH from the market. If the price of ETH has fallen, they can buy it back for less USDC than they initially received, and the difference is their profit.10

In both cases, the liquidity pool acts as the counterparty, either lending the required capital (for longs) or the required asset (for shorts).14 This peer-to-pool mechanism is central to the design of Project Hyperion and will be explored in greater detail in Part II.

### **Chapter 2: Perpetual Futures as the Ideal DeFi Instrument**

To facilitate continuous leveraged trading without the operational complexities of traditional futures contracts, the DeFi ecosystem has overwhelmingly adopted a unique financial instrument: the perpetual futures contract, or "perp".15 These contracts form the engine of modern decentralized leverage platforms like dYdX and GMX and are the ideal choice for Project Hyperion.1

#### **Defining Perpetual Futures**

Perpetual futures are derivative contracts that allow traders to speculate on the price of an underlying asset without an expiration date.15 Unlike traditional futures, which have a fixed settlement date where the contract price must converge with the spot price, perps can be held indefinitely. This design eliminates the need for traders to constantly roll over their positions from an expiring contract to a new one, creating a more seamless and liquid trading experience that closely mimics spot market trading but with the added benefits of leverage and short-selling capabilities.15

The absence of an expiry date presents a unique challenge: how to ensure the perpetual contract's price (the "mark price") stays tethered to the underlying asset's actual market price (the "spot" or "index" price). This is solved by the instrument's most innovative feature: the funding rate mechanism.

#### **The Funding Rate: An Economic Tether**

The **funding rate** is a system of periodic payments exchanged directly between traders holding long and short positions.18 It is not a fee paid to the exchange but a peer-to-peer mechanism designed to incentivize market behavior that pushes the perpetual contract price back towards the spot price.17 These payments typically occur at regular intervals, such as every one or eight hours.15

The direction of the payment depends on the relationship between the perpetual price and the spot price:

* **Positive Funding Rate:** When the perpetual contract trades at a premium to the spot price (perp price \> spot price), it indicates strong buying pressure or bullish sentiment. In this scenario, traders holding **long** positions pay traders holding **short** positions. This makes it more expensive to be long and more profitable to be short, incentivizing traders to open short positions or close long ones, which in turn applies downward pressure on the perpetual price, bringing it closer to the spot price.19  
* **Negative Funding Rate:** When the perpetual contract trades at a discount to the spot price (perp price \< spot price), it indicates strong selling pressure or bearish sentiment. Here, traders holding **short** positions pay traders holding **long** positions. This makes it more expensive to be short, encouraging traders to open long positions and push the perpetual price back up towards the spot price.19

The funding rate is generally calculated as the sum of two components: a premium index and an interest rate component.17 The premium index measures the deviation between the perpetual and spot prices, while the interest rate component accounts for the difference in borrowing costs between the two assets in the pair (e.g., the base asset like ETH and the quote asset like USDC).

This mechanism is not just a technical anchor; it has profound economic consequences. For traders, the funding rate is a direct component of their profit and loss (PnL). A sustained high positive funding rate can significantly erode the profits of a long position over time, while a trader holding a short position would receive a steady stream of income.19 This transforms the funding rate into a key strategic consideration, especially for those intending to hold positions for extended periods.

#### **The Funding Rate's Dual Role in a Peer-to-Pool System**

In a traditional order book model, the funding rate simply balances the demand between individual long and short traders. However, in the peer-to-pool architecture of Project Hyperion, the mechanism takes on a second, equally critical role: managing the risk of the liquidity pool and incentivizing liquidity providers (LPs).

In this model, the liquidity pool is the counterparty to every trade.14 If there are more traders with long positions than short positions, the pool is implicitly holding the net short position. Conversely, if shorts outweigh longs, the pool is implicitly long. This means the pool itself becomes one side of the funding rate equation.

Consider a scenario where bullish sentiment is high, and the total value of long positions is 10M USDC while the total value of short positions is 2M USDC. The pool is effectively short 8M USDC. Because the perpetual price will likely trade at a premium, the funding rate will be positive. This means the long traders will pay the funding rate, and the short side—in this case, primarily the liquidity pool—will *receive* these payments.

This transforms the funding rate from a simple balancing mechanism into a direct source of yield for the liquidity providers. This yield is in addition to the trading fees they already earn. This dynamic creates a powerful, self-correcting incentive structure. When the pool's exposure becomes heavily skewed in one direction (e.g., net short), the resulting funding rate payments make it more profitable for LPs to provide the capital that backs that exposure. It incentivizes liquidity to flow to the side of the market that is less popular among traders, helping the protocol to naturally hedge its own risk. Therefore, the design of the funding rate calculation for Project Hyperion must be more sophisticated than in a peer-to-peer system; it must account not only for the price deviation but also for the open interest imbalance within the pool to ensure the long-term stability and profitability of the liquidity providers.

### **Chapter 3: The Imperative of Liquidation**

Leverage, by its nature, creates the risk that a trader's losses could exceed the value of their deposited collateral. To prevent this from happening and to protect the solvency of the protocol, a robust liquidation mechanism is not just a feature—it is an absolute necessity.24 Liquidation is the forced closure of a trader's position, a non-negotiable safeguard that ensures the protocol never incurs "bad debt".26

#### **The Mechanics of Solvency: Key Liquidation Concepts**

The liquidation process is governed by a set of precise thresholds and parameters defined within the protocol's smart contracts.

* **Initial Margin:** As established, this is the collateral required to open a position. For a 10x leverage trade, the initial margin is 10% of the total position size.8  
* **Maintenance Margin (MM):** This is the *minimum* amount of margin (equity) a trader must maintain to keep their position open. It acts as a buffer, ensuring there is enough collateral to close the position without leaving the protocol with a loss, even in a volatile market. The Maintenance Margin is typically set as a small percentage of the total position size, for example, 5%.6  
* **Liquidation Price:** This is the calculated price of the underlying asset at which a trader's position becomes eligible for liquidation. It is the price at which the trader's losses have eroded their initial margin down to the maintenance margin level.27 When the market price, as reported by the oracle, crosses this threshold, the liquidation process can be triggered.  
* **Bankruptcy Price:** This is the theoretical price at which a trader's losses are exactly equal to their entire initial margin.28 At this point, the trader has lost all their collateral. The entire purpose of the maintenance margin and the liquidation process is to close the position  
  *before* it reaches the bankruptcy price, ensuring the protocol can cover the position's closure and associated fees without incurring a loss.

#### **The Liquidation Process in DeFi**

Unlike in traditional finance, which involves margin calls and manual interventions, liquidation in DeFi is an automated, transparent, and permissionless process executed by smart contracts.25 The process typically unfolds as follows:

1. **Trigger:** The protocol's smart contracts continuously monitor the health of every open position. This is often represented by a "Health Factor," which is a ratio of the position's collateral value to its debt.25 When the market price moves against a trader, their unrealized losses increase, their effective margin decreases, and their Health Factor drops. Once the Health Factor falls below a predefined threshold (typically 1), or the asset's oracle price crosses the calculated liquidation price, the position is flagged as undercollateralized and becomes eligible for liquidation.  
2. **Execution by Liquidators:** The actual act of liquidation is typically initiated by an external, third-party actor known as a "liquidator." These are often sophisticated bots that constantly scan the blockchain for positions eligible for liquidation.26 Because the liquidation function in the smart contract is public, anyone can act as a liquidator.  
3. **The Liquidator's Incentive:** To incentivize this crucial ecosystem service, liquidators are rewarded for their actions. When a liquidator calls the liquidation function, they typically repay the underwater position's debt to the protocol. In return, they are allowed to claim the trader's collateral at a discount to its current market value. This discount is known as the **liquidation penalty** or **liquidation bonus**.26 For example, a liquidator might repay a 9,500 USDC debt and receive 10,000 USDC worth of the trader's collateral, making a risk-free profit. This incentive ensures that, in a healthy market, undercollateralized positions are closed swiftly.  
4. **Partial vs. Full Liquidation:** While simpler protocols might perform a full liquidation, more advanced systems may opt for partial liquidation. In this model, only a portion of the position is closed—just enough to restore the margin to a healthy level. This approach minimizes the market impact of large liquidations and is less punitive for the trader.30 For the initial version of Project Hyperion, a full liquidation model is recommended for its simplicity, with partial liquidation being a potential future upgrade.

#### **Table: Liquidation Price Calculation Example**

To build the liquidation engine, the development team must have a precise mathematical understanding of how the liquidation price is derived. The formulas differ for long and short positions. The following table provides a concrete example and the underlying formulas, which will serve as a direct specification for the PositionManager.sol contract.

| Parameter | Value / Formula | Description |
| :---- | :---- | :---- |
| **Scenario Setup** |  | A user deposits 1,000 USDC to trade ETH, which is currently priced at $3,000 per ETH. |
| Collateral | 1,000 USDC | The initial margin deposited by the user. |
| Leverage | 10x | The leverage multiple chosen by the user. |
| Entry Price | $3,000 | The price of ETH at the time the position is opened. |
| Position Size (Value) | 10,000 USDC | Collateral \* Leverage |
| Position Size (Asset) | 3.333 ETH | Position Size (Value) / Entry Price |
| Initial Margin Rate (IMR) | 10% | 1 / Leverage |
| Maintenance Margin Rate (MMR) | 5% | A protocol-defined parameter. This is a critical risk setting. |
| Maintenance Margin (MM) | 500 USDC | Position Size (Value) \* MMR |
| **Long Position Liquidation** |  | The user is betting the price of ETH will go up. Liquidation occurs if the price falls. |
| **Liquidation Price (Long)** | **$2,715.00** | Entry Price \* (1 \- IMR \+ MMR) is a common approximation. A more precise formula is: Liquidation Price \= Entry Price \- (Collateral \- Maintenance Margin) / Position Size (Asset). Calculation: $3000 \- (1000 \- 500\) / 3.333 \= $3000 \- 150 \= $2850. *Correction based on common exchange formulas which account for leverage directly:* Liquidation Price \= Entry Price \* (1 \- (1/Leverage) \+ MMR). Calculation: $3000 \* (1 \- 0.1 \+ 0.05) \= $3000 \* 0.95 \= $2850. A more precise formula considering the position value is: Liquidation Price \= (Position Value \- Collateral \+ Maintenance Margin) / Position Size (Asset). Let P\_liq be the liquidation price. Collateral \- (Entry Price \- P\_liq) \* Size\_asset \= MM. 1000 \- (3000 \- P\_liq) \* 3.333 \= 500\. 500 \= (3000 \- P\_liq) \* 3.333. 150 \= 3000 \- P\_liq. P\_liq \= 2850\. |
| **Short Position Liquidation** |  | The user is betting the price of ETH will go down. Liquidation occurs if the price rises. |
| **Liquidation Price (Short)** | **$3,150.00** | Using the same logic as above: Let P\_liq be the liquidation price. Collateral \- (P\_liq \- Entry Price) \* Size\_asset \= MM. 1000 \- (P\_liq \- 3000\) \* 3.333 \= 500\. 500 \= (P\_liq \- 3000\) \* 3.333. 150 \= P\_liq \- 3000\. P\_liq \= 3150\. |

*Note: These calculations exclude fees and funding rate payments for simplicity. In a live environment, these costs would also erode the position's margin and move the liquidation price closer to the entry price over time.*

---

## **Part II: Architectural Blueprint and System Design**

With a firm grasp of the core financial mechanics, the next step is to translate theory into a coherent system architecture. This involves making high-level design choices that will define the protocol's functionality, scalability, and risk profile. This section evaluates the dominant architectural paradigms in decentralized perpetuals trading, justifies the selection of a peer-to-pool model for Project Hyperion, and lays out a detailed blueprint for its on-chain and off-chain components.

### **Chapter 4: A Comparative Analysis of DEX Architectures**

The decentralized exchange (DEX) landscape for perpetuals is primarily dominated by two distinct architectural models: the off-chain order book and the peer-to-pool (or shared liquidity) model.3 Each approach presents a different set of trade-offs regarding performance, liquidity, and user experience.

#### **The Two Dominant Models**

1. Model 1: Off-Chain Order Book (e.g., dYdX)  
   This model closely mimics the architecture of centralized exchanges (CEXs). User orders to buy and sell are collected and matched in a high-performance, off-chain order book. In the case of dYdX's v4 architecture, this order book is managed by the network's validators in-memory.33 Only when a trade is matched and executed is the result committed to the blockchain for settlement. This design allows for extremely high throughput, enabling thousands of order placements and cancellations per second, and provides a familiar trading experience with features like limit orders and a visible market depth chart.23 Liquidity in this model is typically provided by professional market makers who actively place bids and asks on the order book, creating a competitive market with tight spreads.23 The primary challenge for this model is bootstrapping and maintaining sufficient market maker liquidity to ensure a good trading experience.  
2. Model 2: Peer-to-Pool / Shared Liquidity (e.g., GMX, Synthetix)  
   This model, also known as a peer-to-contract model, eschews a traditional order book entirely.14 Instead, it features a single, large liquidity pool composed of assets deposited by liquidity providers (LPs). This pool serves as the direct counterparty for every trade.2 When a trader wants to go long, they are essentially trading against the pool; when they want to go short, they are also trading against the pool.  
   Price determination in this model is not based on the intersection of buy and sell orders. Instead, prices are fed into the system by an external, decentralized oracle network like Chainlink.2 This has a profound consequence: trades can be executed with  
   **zero slippage**. Slippage, the difference between the expected price of a trade and the price at which it is executed, is a major cost in order book models, especially for large orders that "walk the book." In a peer-to-pool model, a trade of any size executes at the exact price provided by the oracle.23 This model is also highly capital-efficient for LPs, as their deposited funds provide liquidity across all price points simultaneously, rather than being concentrated on specific bids or asks.23 The primary challenge for this model is managing the risk of the liquidity pool, which is constantly exposed to the net positions of all traders.

#### **Justifying the Peer-to-Pool Model for Project Hyperion**

The user query for Project Hyperion explicitly requests a "pool to pay out profits or receive funds upon liquidation," which directly specifies the peer-to-pool architectural model. This choice is further justified by its inherent advantages for a new protocol:

* **Simplified Liquidity Provision:** Attracting passive LPs who can simply deposit assets and earn fees is often easier than recruiting active, professional market makers required for an order book model.  
* **Superior User Experience (Zero Slippage):** The guarantee of zero-slippage trades is a powerful value proposition that can attract traders, as it eliminates a significant and often unpredictable trading cost.  
* **Capital Efficiency:** A single, unified pool of liquidity can support a deep and robust market more effectively than fragmented liquidity across an order book, especially in the early stages of a protocol's life.

The following table provides a clear, at-a-glance comparison of these models, reinforcing the strategic choice for Project Hyperion.

#### **Table: Comparative Analysis of DEX Architectural Models**

| Feature | Off-Chain Order Book (dYdX v4) | Peer-to-Pool (GMX) | Project Hyperion (Proposed) |
| :---- | :---- | :---- | :---- |
| **Liquidity Source** | Professional Market Makers | Passive Liquidity Providers (LPs) | Passive Liquidity Providers (LPs) |
| **Trade Execution** | Off-chain matching engine, on-chain settlement | On-chain execution against a pool | On-chain execution against a pool |
| **Price Determination** | Bid/Ask spread in order book | External Oracle Price Feeds | External Oracle Price Feeds |
| **Slippage** | Yes, dependent on order book depth | No, trades execute at oracle price | No, trades execute at oracle price |
| **Counterparty** | Another trader | The Liquidity Pool | The Liquidity Pool |
| **Scalability** | High throughput (off-chain ordering) | Limited by underlying blockchain TPS | Limited by Ethereum L1 TPS |
| **Key Challenge** | Attracting and retaining market maker liquidity | Balancing pool exposure & LP incentives | Balancing pool exposure & LP incentives |
| **Relevant References** | 33 | 2 | User Query, GMX Architecture |

### **Chapter 5: The Hyperion Protocol Architecture: A GMX-Inspired Design**

Having committed to the peer-to-pool model, we can now define the specific architecture for Project Hyperion. The design will be heavily inspired by the modular and robust architecture of GMX V2, which separates concerns into distinct, auditable contracts and relies on an asynchronous execution model for key functions.38

#### **High-Level System Diagram**

The Hyperion protocol can be visualized as a system of interacting on-chain and off-chain components:

* **User:** Interacts with the dApp via a web browser and a crypto wallet (e.g., MetaMask).  
* **Frontend (dApp):** A React-based web application that provides the user interface for trading and liquidity provision. It communicates with the user's wallet and sends transactions to the Router contract.  
* **On-Chain Smart Contracts (Ethereum):**  
  * Router.sol: The public-facing gateway contract.  
  * PositionManager.sol: The core logic engine.  
  * Vault.sol: The secure treasury holding all protocol assets.  
  * GLPToken.sol: The ERC-20 token representing LP shares.  
* **External Dependencies & Off-Chain Actors:**  
  * **Chainlink Oracle:** Provides real-time, decentralized price data to the PositionManager.  
  * **Keepers:** Off-chain bots that monitor the protocol and trigger time-sensitive functions like liquidations and funding rate updates.  
  * **Indexer (Optional):** An off-chain service that reads and organizes blockchain data to serve it efficiently to the frontend.

#### **On-Chain Components: The Smart Contract Suite**

The on-chain logic of Project Hyperion will be encapsulated in a suite of specialized, interoperable smart contracts. This modular design enhances security and maintainability.38

* **Router.sol:** This contract serves as the sole entry point for all user-initiated transactions. It will not contain any complex business logic itself. Instead, its purpose is to receive calls from the user's frontend, perform initial validation of inputs (e.g., ensuring amounts are not zero), and then route the request to the appropriate internal function within the PositionManager.38 This approach simplifies frontend development, centralizes access control, and creates a clear, narrow surface for security audits.  
* **Vault.sol:** This contract is the protocol's treasury. It will hold all user-deposited collateral (e.g., USDC) and the assets that constitute the liquidity pool (e.g., ETH, WBTC). The Vault will be intentionally simple, with its primary functions being to accept deposits and process withdrawals. Crucially, these functions will have strict access controls, allowing them to be called *only* by the PositionManager contract. This separation of asset holding from complex business logic is a critical security principle, minimizing the attack surface of the contract that directly controls the funds.9  
* **PositionManager.sol:** This is the "brain" of the protocol. It will house the entirety of the core trading and risk management logic. Its responsibilities will include:  
  * Creating, updating, and closing user positions.  
  * Calculating unrealized profit and loss (PnL) for all open positions based on the latest oracle price.  
  * Calculating and tracking the funding rate based on the imbalance between long and short open interest.  
  * Executing the periodic exchange of funding payments between traders and the liquidity pool.  
  * Continuously calculating the liquidation price for every position.  
  * Handling the logic for liquidations when triggered by a Keeper.  
    This contract will have the authority to instruct the Vault to move funds and to mint/burn GLPTokens.  
* **GLPToken.sol:** This will be an ERC-20 compliant token that represents a liquidity provider's share in the main liquidity pool.9 When an LP deposits assets (e.g., USDC, ETH) into the  
  Vault via the Router, the PositionManager will calculate the value of their deposit relative to the total value of the pool and mint a corresponding amount of GLPTokens to the LP's wallet.38 The value of the GLP token will fluctuate as the pool earns trading fees and funding payments, and as it incurs losses or gains from traders' PnL. To withdraw their liquidity, LPs will burn their GLP tokens to claim their proportional share of the assets in the  
  Vault.

#### **Off-Chain Components: The Support Infrastructure**

While the core logic is on-chain, the protocol cannot function in a vacuum. It relies on a set of off-chain services to operate efficiently and securely.

* **Keepers:** These are automated, off-chain programs (bots) that play an essential role in the protocol's lifecycle.38 Because blockchain transactions must be initiated by an externally owned account (EOA), smart contracts cannot trigger themselves at a specific time or based on a condition alone. Keepers bridge this gap. Their primary tasks in Project Hyperion will be:  
  1. **Monitoring for Liquidations:** Continuously querying the PositionManager contract to check for any positions that have become liquidatable.  
  2. **Triggering Liquidations:** Calling the public liquidatePosition() function when a liquidatable position is found.  
  3. **Updating Funding Rates:** Calling a public updateFunding() function at the end of each funding period (e.g., every 8 hours) to trigger the calculation and settlement of funding payments.  
* **Frontend (dApp):** This is the user-facing web application, likely built with a modern JavaScript framework like React.33 It will provide the interface for users to connect their wallets, open and manage trades, and provide/withdraw liquidity. It will interact directly with the  
  Router.sol smart contract to send transactions.40  
* **Indexer:** While a basic frontend can read data directly from an Ethereum node, this can be slow and inefficient for complex data queries (e.g., fetching a user's entire trade history). An **Indexer** is an off-chain service that listens to events emitted by the smart contracts, processes this data, and stores it in a traditional database (e.g., PostgreSQL). It then exposes this data to the frontend via a fast, standard web API.33 This significantly improves the dApp's performance and user experience. While optional for an initial prototype, an indexer is a necessity for a production-grade platform.

#### **The Keeper's Dilemma: A Centralization vs. Decentralization Trade-off**

The reliance on Keepers for critical functions like liquidation introduces a nuanced challenge that lies at the intersection of technology, economics, and game theory. While essential for automation, the Keeper model presents a potential vector for centralization and creates its own set of risks that must be carefully managed.

Initially, the Project Hyperion team will likely need to run its own Keeper bots to ensure that liquidations and funding updates occur reliably. This, however, represents a single point of failure. If the team's Keepers go offline, the protocol's risk management system could grind to a halt, potentially leading to an accumulation of unliquidated, undercollateralized positions and threatening the solvency of the pool.

The long-term solution is to decentralize this function by making the Keeper-callable functions (liquidatePosition, updateFunding) permissionless and publicly callable, as seen in protocols like Compound.26 This allows a competitive ecosystem of third-party, profit-motivated Keepers to emerge. However, this creates a new economic problem: incentives. A third-party Keeper will only execute a transaction if it is profitable to do so, meaning the financial reward (e.g., the liquidation bonus) must exceed the gas cost of the transaction.26

During periods of extreme market volatility and network congestion, Ethereum gas fees can skyrocket. In such a scenario, it might become unprofitable for Keepers to liquidate smaller positions, as the gas cost could outweigh the liquidation bonus. This precise scenario contributed to the "Black Thursday" crisis for MakerDAO in March 2020, where a cascade of liquidations was hampered by network congestion, leading to significant protocol losses.31 Furthermore, the open competition for liquidation bonuses creates a fertile ground for Maximal Extractable Value (MEV) bots, who will engage in priority gas auctions (PGAs) to front-run each other, potentially driving up gas fees even further for all network users.41

This reality dictates that the design of the liquidation bonus and the gas efficiency of the liquidation function are not minor implementation details. They are paramount to the protocol's survival under stress. The liquidation bonus must be dynamically calibrated or sufficiently large to remain attractive even during periods of high gas fees. The liquidatePosition function must be ruthlessly optimized for gas efficiency. The project's roadmap must therefore include not only a plan to run initial, reliable Keeper infrastructure but also a strategy to foster and sustain a healthy, decentralized ecosystem of third-party Keepers through robust economic incentives and sound technical design.

---

## **Part III: The Smart Contract Core: Implementation in Solidity**

This section transitions from high-level architecture to the concrete implementation of Project Hyperion's on-chain logic. It provides detailed specifications for the key smart contracts, written in Solidity, the primary programming language for the Ethereum Virtual Machine (EVM). The design will heavily leverage the battle-tested and secure libraries provided by OpenZeppelin to mitigate common vulnerabilities and adhere to best practices.42

### **Chapter 6: The Collateral Vault and GLP Token**

The foundation of the protocol's asset management is a secure vault and a token to represent shares within it. These components are designed for simplicity and security, isolating asset storage from the more complex trading logic.

#### **Vault.sol: The Protocol Treasury**

The Vault.sol contract serves a single, critical purpose: to securely hold all assets managed by the Hyperion protocol. It acts as a digital treasury, ensuring that the collateral and liquidity pool funds are segregated from the intricate business logic housed in other contracts.

* **Purpose and Design Philosophy:** The core design principle for the Vault is minimalism. By limiting its functionality to basic deposit and withdrawal actions, we drastically reduce its attack surface. It will contain no logic related to trading, PnL calculation, or liquidations. Its sole responsibility is accounting.  
* **State Variables:**  
  * address public positionManager;: Stores the address of the PositionManager contract, which will be the only contract authorized to instruct the Vault. This will be set in the constructor and made immutable.  
  * mapping(address \=\> uint256) public totalAssets;: A mapping to track the total balance of each ERC-20 token held within the Vault. The key is the token's contract address (e.g., USDC, WETH), and the value is the total amount.  
* **Core Functions:**  
  * constructor(address \_positionManager): Initializes the contract, setting the address of the trusted PositionManager.  
  * deposit(address \_token, uint256 \_amount): A function to handle the transfer of tokens *into* the Vault. It will use the ERC-20 transferFrom method to pull funds from the msg.sender (which will be the PositionManager). It will only be callable by the positionManager address.  
  * withdraw(address \_token, address \_recipient, uint256 \_amount): A function to handle the transfer of tokens *out of* the Vault. It will use the ERC-20 transfer method to send funds to a specified recipient. This function will also be strictly controlled, callable only by the positionManager.

This strict separation ensures that even if a complex vulnerability were found in the PositionManager, the attacker could not directly drain the Vault without going through the PositionManager's controlled pathways.

#### **GLPToken.sol: The Liquidity Provider Token**

The GLPToken.sol contract provides the mechanism for tokenizing liquidity provision. It gives LPs a liquid, transferable asset that represents their claim on the underlying assets in the liquidity pool.

* **Standard and Implementation:** The GLP token will be a standard ERC-20 token, adhering to the interface defined in EIP-20.39 To ensure security and correctness, its implementation will be inherited directly from OpenZeppelin's  
  ERC20.sol and Ownable.sol contracts.42 This provides all standard functionalities like  
  transfer, approve, balanceOf, etc., out of the box.  
* **Minting and Burning Authority:** The PositionManager contract will be designated as the "owner" of the GLPToken contract. This will grant it the exclusive authority to mint new GLP tokens and burn existing ones.  
  * **Minting:** When a liquidity provider deposits assets into the Vault, the PositionManager will calculate the number of new GLP tokens to create based on the current exchange rate between the deposited assets and the existing GLP supply. It will then call a mint(address to, uint256 amount) function on the GLPToken contract.  
  * **Burning:** When an LP wishes to withdraw their liquidity, they will first approve the PositionManager to spend their GLP tokens. They will then call a function on the PositionManager, which will in turn call a burn(uint256 amount) function on the GLPToken contract, permanently destroying the tokens before releasing the underlying assets from the Vault.44

The exchange rate for GLP will be determined by the formula: GLP Price \= Total Value of Assets in Vault / Total Supply of GLP. This ensures that as the pool accrues fees, the value of each GLP token appreciates, rewarding the LPs.

### **Chapter 7: The Position Manager: The Brain of the Protocol**

The PositionManager.sol contract is the operational core of Project Hyperion. It orchestrates all the complex logic of the trading system, acting as the central nervous system that connects the Vault, the Router, the oracle, and the users' positions.

* **Purpose and Responsibilities:** This contract is responsible for the entire lifecycle of a trade, from opening to closing or liquidation. It maintains the state of every position and enforces the protocol's rules.  
* **Key State Variables:**  
  * address public immutable vault;: The address of the Vault contract, set at deployment.  
  * address public immutable router;: The address of the Router contract.  
  * address public immutable glpToken;: The address of the GLPToken contract.  
  * AggregatorV3Interface internal priceFeed;: An interface instance to interact with the Chainlink price oracle.  
  * struct Position { address account; address collateralToken; address indexToken; uint256 size; uint256 collateralValue; uint256 entryPrice; bool isLong; uint256 lastFundingTime; }: A detailed struct to store all relevant information about a single open position.  
  * mapping(bytes32 \=\> Position) public positions;: A mapping from a unique, user-specific position key (e.g., keccak256(abi.encodePacked(userAddress, positionIndex))) to the Position struct.  
  * uint256 public totalLongInterest;: The total value of all open long positions.  
  * uint256 public totalShortInterest;: The total value of all open short positions.  
  * Variables to store funding rate parameters, such as the funding interval and last update time.  
* Core Logic Functions (Internal):  
  The true complexity of the PositionManager lies in its internal helper functions, which will be called by the public-facing functions exposed through the Router.  
  * \_getOraclePrice(address \_indexToken): An internal function that queries the Chainlink priceFeed to get the latest price for a given asset, returning it as a standardized value (e.g., with 18 decimals). It will include checks for data freshness and validity.  
  * \_calculatePnl(Position memory \_position): This function takes a Position struct as input and calculates its current unrealized profit or loss. For a long position, PnL \= (Current Price \- Entry Price) \* Size. For a short position, PnL \= (Entry Price \- Current Price) \* Size.  
  * \_calculateLiquidationPrice(Position memory \_position): Implements the precise mathematical formulas for determining the liquidation price, as detailed in the table in Chapter 3\. This function is critical for both on-chain liquidation checks and for displaying information to the user on the frontend.  
  * \_updateFundingRate(): This function will be called periodically by a Keeper. It calculates the funding rate based on the skew between totalLongInterest and totalShortInterest and the deviation of the mark price from the index price. It will then iterate through open positions (or use a more gas-efficient accounting method) to apply these funding payments, either debiting or crediting each position's collateral value.  
  * \_isLiquidatable(Position memory \_position): This function combines the PnL calculation with the margin requirements. It calculates the current margin of the position (Initial Collateral \+ PnL) and checks if this value has fallen below the required Maintenance Margin. It returns true if the position is eligible for liquidation.

### **Chapter 8: The Router Contract: The Public Gateway**

The Router.sol contract acts as the bouncer and receptionist for the protocol. It provides a clean, secure, and stable public API for all external interactions, shielding the complex internal machinery of the PositionManager from direct user access.

* **Purpose and Design:** The primary goal of the Router is to simplify user interaction and enhance security. By channeling all requests through a single contract, we can enforce consistent input validation and access control. The Router's address will be the one that users and frontends interact with, while the PositionManager's address can remain more insulated.  
* User-Facing Functions (External/Public):  
  These functions will form the public Application Binary Interface (ABI) of the protocol. They will perform necessary checks (require statements) on the inputs before forwarding the call to the PositionManager.  
  * openPosition(address \_collateralToken, uint \_collateralAmount, address \_indexToken, bool \_isLong, uint \_leverage): The primary function for traders. It will check that the leverage is within the protocol's allowed range (e.g., 1x to 10x) and that the collateral amount is above a minimum threshold, then call the corresponding function on the PositionManager.  
  * closePosition(bytes32 \_positionKey): Allows a user to close their position. It will verify that the msg.sender is the owner of the position before proceeding.  
  * addCollateral(bytes32 \_positionKey, uint \_amount): Allows a user to add more margin to an existing position to move their liquidation price further away.  
  * depositLiquidity(address \_token, uint \_amount): The entry point for LPs. It accepts a deposit of an approved asset (e.g., USDC, WETH) and triggers the minting of GLP tokens.  
  * withdrawLiquidity(uint \_glpAmount): The exit point for LPs. It handles the burning of GLP tokens and the return of the underlying assets.

The following table summarizes the core functions that define the protocol's public surface area, providing a clear specification for both backend and frontend development.

#### **Table: Core Smart Contract Function Specifications**

| Contract | Function Signature | Visibility | Description | Key References |
| :---- | :---- | :---- | :---- | :---- |
| Router | openPosition(address, uint256, address, bool, uint256) | external | User entry point to open a new long or short leveraged position. Validates inputs and forwards to the Position Manager. | 38 |
| Router | closePosition(bytes32 \_positionKey) | external | User entry point to close an existing position and realize profit or loss. Verifies ownership. | 38 |
| Router | depositLiquidity(address \_token, uint256 \_amount) | external | LP entry point to add funds to the liquidity pool and receive newly minted GLP tokens in return. | 9 |
| Router | withdrawLiquidity(uint256 \_glpAmount) | external | LP entry point to burn GLP tokens and withdraw their proportional share of the pool's assets. | 9 |
| PositionManager | liquidatePosition(bytes32 \_positionKey) | public | Keeper-callable function to force-close an undercollateralized position. This is permissionless but requires a profitability check. | 26 |
| PositionManager | updateFundingRate() | public | Keeper-callable function to trigger the periodic funding payment exchange between traders and the liquidity pool. | 19 |
| Vault | deposit(address, uint256) | internal | Called exclusively by PositionManager to transfer funds into the vault for safekeeping. | 9 |
| Vault | withdraw(address, address, uint256) | internal | Called exclusively by PositionManager to transfer funds out of the vault upon position closure or withdrawal. | 9 |

---

## **Part IV: The Oracle System and Liquidation Engine**

A decentralized perpetuals protocol is fundamentally a risk management system. Its ability to remain solvent and function correctly depends entirely on two external processes: receiving accurate, real-time price data and ensuring that undercollateralized positions are liquidated in a timely manner. This section details the design and integration of these two critical subsystems for Project Hyperion.

### **Chapter 9: Integrating Chainlink Price Feeds**

Smart contracts, by design, are deterministic and isolated from the outside world. They cannot natively access external information like the current market price of ETH.46 This fundamental limitation is known as the

**"oracle problem"**.47 To solve this, protocols must rely on a third-party service—an oracle—to fetch off-chain data and deliver it securely onto the blockchain.48 The integrity of the oracle is paramount; if the price data it provides is inaccurate or manipulated, the protocol can be tricked into executing wrongful liquidations or paying out incorrect profits, leading to catastrophic financial loss.49

#### **Why Chainlink is the Industry Standard**

For a protocol like Hyperion, where billions of dollars in value could eventually be at stake, relying on a centralized oracle or a single data source is an unacceptable risk.48 This is why

**Chainlink** has become the undisputed industry standard for decentralized oracle networks (DONs).47 Chainlink's security model is built on decentralization at multiple layers:

* **Decentralized Data Sources:** Chainlink Price Feeds do not rely on a single exchange. They aggregate price data from numerous high-quality, professional data aggregators, each of which reflects a volume-weighted average of prices from hundreds of exchanges. This prevents manipulation on any single, low-liquidity market from affecting the final price.50  
* **Decentralized Node Operators:** The aggregated data is fetched and reported on-chain by a decentralized network of independent, security-reviewed, and Sybil-resistant node operators. The final price reported to the smart contract is the median of the responses from these nodes, making it extremely resilient to any single node being compromised or providing faulty data.47  
* **Verifiable On-Chain Data:** All data is published on-chain, creating a transparent and auditable trail that allows anyone to verify the performance of the oracle network.

#### **Implementation Guide for Chainlink Price Feeds**

Integrating Chainlink Price Feeds into the PositionManager.sol contract is a straightforward process that involves the following steps:

1. **Identify the Correct Price Feed Address:** Chainlink maintains a list of deployed Price Feed contracts for various asset pairs on different blockchain networks. The development team must select the correct address for the assets they wish to support (e.g., ETH/USD) on the target network (e.g., Ethereum Mainnet or the Sepolia testnet for development).51  
2. Import the AggregatorV3Interface: This standard interface defines the functions available on all Chainlink Price Feed contracts. It should be imported into the PositionManager.sol contract.  
   import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";  
3. Instantiate the Interface: In the contract's state, an instance of the interface is created and linked to the specific Price Feed address identified in step 1\.  
   AggregatorV3Interface internal priceFeed;  
   constructor() { priceFeed \= AggregatorV3Interface(0x...); // Address of the ETH/USD feed }  
4. **Retrieve the Latest Price:** The price is retrieved by calling the latestRoundData() function. This function returns several values, but the most important are the price (answer), the timestamp of the update (updatedAt), and the round ID (roundId).51  
   Solidity  
   function getLatestPrice() public view returns (int) {  
       (  
           /\*uint80 roundId\*/,  
           int answer,  
           /\*uint startedAt\*/,  
           uint256 updatedAt,  
           /\*uint80 answeredInRound\*/  
       ) \= priceFeed.latestRoundData();  
       // Add checks for data freshness and validity  
       require(updatedAt \> block.timestamp \- 3600, "Stale price"); // e.g., price is not older than 1 hour  
       require(answer \> 0, "Invalid price");  
       return answer;  
   }

   It is crucial to include checks to ensure the data is not stale. For example, the contract should verify that the updatedAt timestamp is recent, preventing the protocol from operating on outdated price information during a period of oracle downtime or network congestion.

#### **Table: Chainlink Price Feed Addresses (Sepolia Testnet)**

For development and testing purposes, Project Hyperion will be deployed on the Sepolia testnet. The following table provides the necessary, ready-to-use contract addresses for common asset pairs on this network.

| Pair | Address | Decimals |  |
| :---- | :---- | :---- | :---- |
| ETH / USD | 0x694AA1769357215DE4FAC081bf1f309aDC325306 | 8 |  |
| BTC / USD | 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43 | 8 |  |
| LINK / USD | 0xc59E3633BAAC79493d908e63626716e204A45EdF | 8 |  |
| Source: Official Chainlink Documentation 52 |  |  |  |

### **Chapter 10: Building the Liquidation Mechanism**

The liquidation engine is the protocol's ultimate defense mechanism. It must be efficient, reliable, and economically incentivized to ensure that the liquidity pool is never left with bad debt. As established, this process is not self-executing; it relies on off-chain Keeper bots to trigger the on-chain liquidation logic.38

#### **The Keeper's Role and the Public Liquidation Function**

The liquidatePosition(bytes32 \_positionKey) function within the PositionManager.sol contract must be declared as public or external. This makes it permissionlessly callable by any external account, allowing the decentralized network of Keepers to compete to execute liquidations.26

#### **The On-Chain Liquidation Logic**

When a Keeper calls liquidatePosition, the function must execute a precise sequence of operations:

1. **Verification:** The function must first verify that the position is indeed eligible for liquidation. It will call the internal \_isLiquidatable(\_positionKey) function, which uses the latest oracle price to check if the position's margin has fallen below the maintenance margin requirement. This is a critical require check to prevent solvent positions from being wrongfully liquidated.  
2. **Position Closure:** The position is marked as closed. The contract calculates the final PnL based on the current oracle price.  
3. **Collateral Seizure and Debt Repayment:** The user's entire collateral associated with the position is seized by the protocol. The value of this collateral is used to first repay the user's debt to the liquidity pool (the notional value of the position minus the initial margin).  
4. **Penalty and Incentive Calculation:** A **liquidation penalty** is applied. This is a percentage (e.g., 5-10%) of the position's remaining collateral value.26 This penalty serves two purposes: it discourages traders from allowing their positions to get close to liquidation, and it funds the incentive for the liquidator.  
5. **Distribution:** The funds are distributed.  
   * The Keeper who called the function (msg.sender) receives a portion of the liquidation penalty as their **liquidation bonus** or reward.  
   * The remaining portion of the penalty can be added to the protocol's treasury, which ultimately accrues value to the GLP token holders.  
   * After the debt is repaid and all penalties are deducted, if there is any collateral value remaining (a rare occurrence), it is returned to the liquidated trader.

#### **Gas Costs and Economic Viability**

A significant risk to the liquidation mechanism is economic non-viability due to high gas fees.26 During periods of intense market volatility—precisely when liquidations are most needed—the Ethereum network can become highly congested, causing gas prices to spike. If the gas cost to call the

liquidatePosition function exceeds the value of the liquidation bonus, no rational Keeper will trigger the liquidation. This can lead to a "death spiral" where undercollateralized positions accumulate, the protocol incurs bad debt, and the value of the GLP token plummets.

To mitigate this, the liquidatePosition function must be engineered for maximum gas efficiency. This involves minimizing state writes, avoiding complex loops, and optimizing calculations. Furthermore, the protocol governance may need the ability to adjust the liquidation penalty percentage to ensure that the incentive remains attractive even during periods of high network fees. This economic balancing act is a crucial, ongoing challenge for the long-term health of the protocol.

---

## **Part V: Frontend Integration and Project Deployment**

The most sophisticated on-chain protocol is useless without a secure, intuitive, and reliable frontend through which users can interact with it. This section outlines the development of the decentralized application (dApp) interface and provides a strategic roadmap for testing and deploying the entire system, bridging the gap between the Solidity smart contracts and the end-user.

### **Chapter 11: Building the dApp Frontend**

The frontend is the face of Project Hyperion. It must provide a seamless user experience while securely managing interactions with the Ethereum blockchain.

#### **Recommended Technology Stack**

To ensure a modern, robust, and maintainable frontend, a standard Web3 technology stack is recommended:

* **UI Framework:** **React** (or a React-based framework like **Next.js**) is the de facto standard for building complex, interactive web applications and has the most extensive community support and tooling in the Web3 space.53  
* **Blockchain Interaction Library:** **Ethers.js** or **viem/wagmi** are the leading libraries for interacting with Ethereum smart contracts from a JavaScript environment. They provide utilities for parsing contract ABIs, formatting data, sending transactions, and querying blockchain state.40 The  
  wagmi library, built on top of viem, is particularly powerful as it provides a set of React Hooks that greatly simplify state management for wallet connections, network status, and contract interactions.40  
* **Wallet Connector:** To provide a smooth user onboarding experience, a wallet connector library like **RainbowKit** or **Web3Modal** is essential. These libraries offer a clean, pre-built user interface for users to connect a variety of wallets (MetaMask, WalletConnect, Coinbase Wallet, etc.) to the dApp with a single integration point.41

#### **Core Frontend Components**

The dApp's user interface should be organized into several key components, each with a distinct purpose:

1. **Wallet Connection:** This is the entry point for any user. A prominent "Connect Wallet" button will trigger the wallet connector modal, allowing the user to grant the dApp permission to view their address and request transaction signatures.40 Once connected, this component should display the user's truncated address and current network status.  
2. **Trade Interface:** This is the primary trading dashboard. It should include:  
   * Input fields for selecting the asset to trade (e.g., ETH), the position side (Long/Short), the collateral amount, and a slider or input for leverage.  
   * Real-time display of calculated values based on user input, such as the total position size and, most importantly, the **estimated liquidation price**. This provides immediate feedback to the user about their risk.  
   * A clear "Open Position" button that, when clicked, prompts the user to sign the transaction via their wallet.  
3. **Position Display:** A dedicated section or dashboard where users can view their currently open positions. For each position, the UI should display:  
   * The asset, position size, and entry price.  
   * The current unrealized PnL, which should update in real-time by fetching the latest oracle price and calculating the PnL on the client side.  
   * The current value of their margin and their Health Factor or distance to liquidation.  
   * Buttons to add more collateral or to close the position.  
4. **Liquidity Provider (LP) Interface:** A separate area of the dApp for liquidity providers. This component will allow users to:  
   * Deposit approved assets (e.g., USDC, WETH) into the liquidity pool.  
   * View their current balance of GLP tokens and its corresponding USD value.  
   * Track the performance of the GLP token and estimated Annual Percentage Rate (APR) from trading fees and funding.  
   * Initiate a withdrawal by burning their GLP tokens.

#### **Connecting the Frontend to Smart Contracts**

The link between the React application and the on-chain contracts is established through the blockchain interaction library (e.g., ethers.js).56 The process involves two key artifacts from the smart contract compilation process:

1. **Contract Address:** The unique address of the deployed Router.sol contract on the blockchain.  
2. **Contract ABI (Application Binary Interface):** A JSON file that describes the contract's functions, arguments, and return types. It serves as a map for the JavaScript code to correctly format calls to the Solidity contract.40

With these two pieces of information, the frontend can create a Contract instance in JavaScript. To perform **read-only** operations (e.g., fetching the current funding rate), this instance is configured with a **Provider**, which is a read-only connection to an Ethereum node (e.g., via Infura, Alchemy, or the provider injected by MetaMask).40 To perform

**write** operations that change the state of the blockchain (e.g., opening a position), the instance must be configured with a **Signer**, which represents the user's connected wallet and has the ability to sign and send transactions.40

### **Chapter 12: A Roadmap for Testing and Deployment**

A rigorous and methodical approach to testing and deployment is critical to ensure the security and reliability of the protocol. The process should be staged, moving from a local environment to a public testnet before finally deploying to mainnet.

#### **Development and Testing Environment**

A modern Ethereum development framework is essential for an efficient workflow. The two leading choices are:

* **Hardhat:** A flexible and extensible JavaScript-based environment. It provides tools for compiling, deploying, testing, and debugging Solidity smart contracts. Its local network simulation and mainnet forking capabilities are invaluable for testing.55  
* **Foundry:** A newer, powerful, and extremely fast toolkit written in Rust. It allows developers to write their tests directly in Solidity, which can be more intuitive and allows for more complex testing scenarios, including property-based testing (fuzzing).41

The choice between them is a matter of team preference, but both provide the necessary tooling for a professional development cycle.

#### **A Comprehensive Testing Strategy**

Testing cannot be an afterthought; it must be integrated throughout the development process. The strategy should encompass multiple layers:

1. **Unit Testing:** Each function within each smart contract should be tested in isolation to verify its logic. For example, a unit test would confirm that the \_calculatePnl function returns the correct positive value for a profitable long position and the correct negative value for a losing one. The goal should be to achieve near 100% test coverage of the codebase.  
2. **Integration Testing:** These tests verify the interactions *between* the different smart contracts in the system. For example, an integration test would simulate a user calling openPosition on the Router, and then verify that the PositionManager correctly creates the position state and that the Vault receives the correct amount of collateral.  
3. **Mainnet Forking:** This is a powerful technique offered by both Hardhat and Foundry. It allows the developer to create a local copy of the entire Ethereum mainnet state at a specific block. This enables testing complex scenarios in a realistic environment. For instance, one could fork mainnet to test the liquidation of a large position and observe its interaction with real liquidity pools on other protocols like Uniswap, all without spending any real gas or affecting the live network.

#### **Staged Deployment Pipeline**

The deployment of the protocol should follow a cautious, staged pipeline:

1. **Deployment Scripts:** Write scripts using the chosen framework (Hardhat or Foundry) to automate the deployment process. This ensures that contracts are deployed in the correct order and that their constructor arguments (e.g., linking the PositionManager to the Vault) are set correctly.  
2. **Testnet Deployment:** The first public deployment should be to a major Ethereum testnet, such as **Sepolia**.52 This allows the team and the broader community to interact with the live dApp in a realistic environment but without real money at stake. The team will need to acquire testnet ETH and other tokens from a public  
   **faucet** to fund the protocol and allow for user testing.40  
3. **Security Audit and Bug Bounty:** While the testnet deployment is live, the code should undergo at least one, and preferably multiple, professional security audits from reputable firms. Concurrently, launching a bug bounty program can incentivize white-hat hackers to find and report vulnerabilities.  
4. **Mainnet Deployment:** Only after extensive testing, successful audits, and the remediation of any discovered issues should the protocol be deployed to the Ethereum mainnet. The launch should be communicated clearly to the community, and the team should have robust monitoring and emergency procedures in place from day one.

---

## **Part VI: Security and Risk Management**

In the world of decentralized finance, security is not a feature; it is the foundation upon which trust and value are built. The immutable nature of blockchain means that a single vulnerability in a smart contract can lead to the irreversible loss of all user funds.45 For Project Hyperion, a protocol designed to manage leveraged positions and a large pool of capital, a defense-in-depth security strategy is not optional—it is a prerequisite for existence. This final section provides a deep dive into the most critical risks facing the protocol and outlines a comprehensive framework of best practices, dubbed the "Hyperion Shield," to mitigate them.

### **Chapter 13: A Deep Dive into DeFi Security Risks**

The threats facing a DeFi protocol are multifaceted, ranging from subtle bugs in the smart contract code to sophisticated economic exploits that manipulate the protocol's logic.

#### **Smart Contract Vulnerabilities**

These are flaws in the Solidity code itself that can be exploited by attackers.

* **Reentrancy:** This is one of the most infamous and destructive types of smart contract attacks, responsible for the historic DAO hack. A reentrancy attack occurs when a malicious contract calls back into a function on the victim contract before the first invocation of the function has finished executing.49 If the victim contract's state (e.g., a user's balance) is not updated until  
  *after* an external call that transfers funds, the attacker can repeatedly call the withdrawal function, draining funds far in excess of their actual balance. For example, a vulnerable withdraw function might look like this: (bool success, ) \= msg.sender.call{value: amount}(""); require(success); balances\[msg.sender\] \= 0;. The attacker's contract, upon receiving the ether, would immediately call the withdraw function again, before the balance is set to zero.  
* **Integer Overflow and Underflow:** In versions of Solidity before 0.8.0, arithmetic operations on integers did not automatically check for overflow (when a number exceeds its maximum storable value and wraps around to zero) or underflow (when an unsigned integer goes below zero and wraps around to its maximum value). An attacker could exploit this to, for example, underflow their balance to a massive number or cause a critical calculation to produce a nonsensical result.42 While modern Solidity compilers have built-in protection, understanding this vulnerability is crucial, especially when interacting with older, external contracts.  
* **Incorrect Access Control:** A common but devastating error is failing to properly restrict access to critical functions. If a function that allows for changing the protocol's parameters (like the priceFeed address or maintenanceMargin rate) is left public instead of being restricted to an authorized owner (internal or private with an onlyOwner modifier), an attacker could simply call it and take control of the protocol's core mechanics.42

#### **Economic & Oracle Manipulation**

These attacks exploit the protocol's logic and its reliance on external data rather than a direct bug in the code.

* **Price Oracle Manipulation:** While a decentralized oracle network like Chainlink is highly resilient, no system is infallible. An attacker could theoretically attempt to manipulate the price of a low-liquidity asset across multiple exchanges that are sources for the oracle's data aggregators. A more common risk is a protocol mistakenly using a less secure oracle, such as one that sources its price directly from a single on-chain DEX like Uniswap. In this case, an attacker could use a flash loan to execute a massive trade on that DEX, momentarily skewing the price, and then use that manipulated price to trigger an unfair liquidation or take out an undercollateralized loan from the target protocol.49  
* **Flash Loan Attacks:** Flash loans allow a user to borrow millions of dollars of assets with zero collateral, on the condition that the loan is repaid within the same single blockchain transaction.49 Attackers use this immense, temporary capital to orchestrate complex economic attacks. For example, an attacker could:  
  1. Take a massive flash loan of USDC.  
  2. Use the USDC to buy a large amount of an asset (e.g., Asset X) on a DEX, causing its price to spike.  
  3. Go to the Hyperion protocol, where Asset X is now valued at the manipulated high price, and use it as collateral to borrow the maximum amount of a different asset (e.g., ETH).  
  4. Sell the ETH back for USDC.  
  5. Repay the original flash loan, pocketing the borrowed ETH (now in USDC form) as profit.  
     This entire sequence happens atomically in one transaction, leaving the protocol with a bad debt backed by overvalued collateral.49

### **Chapter 14: Implementing Security Best Practices: The Hyperion Shield**

A proactive, multi-layered security posture is the only effective defense against these threats. The "Hyperion Shield" is a framework of non-negotiable best practices that must be implemented throughout the development lifecycle.

* **Use Established, Audited Libraries:** Do not reinvent the wheel, especially for critical security components. The protocol must extensively use battle-tested libraries like **OpenZeppelin**. Their implementations of standards like ERC-20 and security utilities like ReentrancyGuard, Ownable, and Pausable have been audited by numerous experts and are the industry standard for secure development.42  
* **Strictly Adhere to the Checks-Effects-Interactions Pattern:** This design pattern is the single most effective defense against reentrancy attacks and should be treated as a golden rule. Every function that involves an external call or value transfer must follow this order of operations 42:  
  1. **Checks:** Perform all validation and require() statements first (e.g., check if the user has sufficient balance, check for correct permissions).  
  2. **Effects:** Update all relevant state variables *within the contract* (e.g., debit the user's balance in the mapping).  
  3. Interactions: Only after all internal state has been updated, perform the external call (e.g., transfer funds to the user).  
     By updating the state before the external interaction, even if the receiving contract calls back into the function, the initial checks will fail because the balance has already been debited, thus preventing the reentrancy vulnerability.  
* **Mandatory, Comprehensive Auditing:** Before a mainnet launch, the entire codebase must undergo at least one, and preferably two or more, professional security audits from reputable third-party firms specializing in DeFi.43 An audit is not a guarantee of security, but it is an essential process for identifying vulnerabilities that the internal team may have missed.  
* **Implement Robust Monitoring and Emergency Controls:** Security is an ongoing process, not a one-time event.  
  * **Off-Chain Monitoring:** The team must implement robust off-chain monitoring systems to track key protocol metrics and detect anomalous behavior, such as unusually large trades, rapid changes in liquidity, or suspicious transaction patterns from a single address.  
  * **Emergency Stop (Pausable):** The protocol's most critical functions (e.g., opening new positions, depositing liquidity) should be controlled by a "pause" mechanism, inherited from OpenZeppelin's Pausable contract. The ability to pause the system should be controlled by a multi-signature wallet, requiring a threshold of signatures from key stakeholders (e.g., 3-of-5 core team members) to activate. This provides a crucial fail-safe to halt the protocol in the event a critical vulnerability is discovered, allowing the team time to plan a response and protect user funds.42

The following checklist provides a concrete, actionable framework for developers and auditors to systematically review the protocol's security posture.

#### **Table: Smart Contract Security Audit Checklist**

| Category | Checklist Item | Status (Y/N) | Notes | Key References |
| :---- | :---- | :---- | :---- | :---- |
| **Access Control** | Are all state-changing functions protected by appropriate modifiers (e.g., onlyOwner, custom roles)? |  | Ensure only authorized addresses can perform administrative actions. | 42 |
|  | Is visibility correctly specified (public, private, internal, external) for all functions and state variables? |  | Default to the most restrictive visibility possible. | 42 |
| **Common Vulnerabilities** | Is the Checks-Effects-Interactions pattern strictly followed for all external calls and value transfers? |  | Primary defense against reentrancy attacks. | 42 |
|  | Is OpenZeppelin's ReentrancyGuard modifier used on critical functions as a defense-in-depth measure? |  | Redundant protection is good practice. | 42 |
|  | Is the latest stable Solidity compiler version (\>=0.8.0) used? |  | Provides built-in overflow/underflow protection. | 42 |
| **Oracle Security** | Is the oracle a decentralized network (e.g., Chainlink) and not a single on-chain DEX? |  | Mitigates single point of failure and direct manipulation risk. | 57 |
|  | Does the contract check the roundId and timestamp of oracle data to prevent stale price attacks? |  | Ensures the protocol is operating on fresh, valid data. | 51 |
| **Economic Logic** | Are there safeguards against flash loan manipulation (e.g., using time-weighted average prices (TWAPs) if applicable, or other architectural defenses)? |  | Protects against economic exploits that drain protocol value. | 49 |
|  | Is the liquidation logic robust and gas-efficient to prevent it from failing during network congestion? |  | Ensures protocol solvency during market stress. | 26 |
| **Testing & Auditing** | Is there comprehensive unit and integration test coverage for all contract logic? |  | Aim for \>95% line and branch coverage. | 43 |
|  | Has the project undergone at least one professional, third-party security audit? |  | Non-negotiable before mainnet deployment. | 57 |
| **Emergency Controls** | Is there a pausable mechanism controlled by a multi-signature wallet for critical functions? |  | Provides a fail-safe in case of a live exploit. | 42 |

## **Conclusion and Recommendations**

This report has laid out a comprehensive technical blueprint for Project Hyperion, a decentralized perpetuals exchange on the Ethereum blockchain. By systematically deconstructing the core financial primitives, analyzing existing architectural paradigms, and detailing a robust implementation and security plan, this document provides an actionable path from concept to deployment.

The architectural choices made for Project Hyperion are deliberate and grounded in the current state of the DeFi ecosystem. The selection of a **peer-to-pool model** inspired by GMX, utilizing a shared liquidity pool and an external oracle for pricing, offers significant advantages in capital efficiency and user experience by providing deep liquidity and zero-slippage trades.2 The use of

**perpetual futures** as the trading instrument aligns with the industry standard, offering a seamless trading experience without the complexity of contract expiries.15 The reliance on

**Chainlink** for decentralized price feeds and an incentivized, permissionless **Keeper network** for liquidations provides the necessary infrastructure for secure and automated risk management.38

The implementation path forward is clear:

1. **Develop the Smart Contract Core:** Build the Vault, GLPToken, PositionManager, and Router contracts in Solidity, adhering strictly to the specifications and security patterns outlined in Parts III and VI. The use of OpenZeppelin libraries is mandatory.  
2. **Establish a Rigorous Testing Environment:** Utilize Hardhat or Foundry to create a comprehensive test suite covering unit, integration, and mainnet forking scenarios. The goal is to simulate and validate every possible state transition and edge case before any public deployment.  
3. **Build the Frontend and Off-Chain Infrastructure:** Develop the React-based dApp for user interaction and stand up the initial Keeper bots required to manage liquidations and funding rates. Plan for the development of an indexer to ensure a scalable and performant user experience.  
4. **Engage in a Staged and Secure Deployment:** Deploy first to the Sepolia testnet for public testing. During this phase, engage multiple reputable security firms for exhaustive audits and launch a public bug bounty program. Only after all identified issues are remediated and the team has high confidence in the system's resilience should a mainnet launch be considered.

The journey of building a DeFi protocol is fraught with technical, economic, and security challenges. The greatest risks lie not only in code-level bugs but in the potential for unforeseen economic interactions and the constant threat of sophisticated exploits. Therefore, the development team must cultivate a culture of paramount security, prioritizing safety and resilience above all else. By following the principles and specifications detailed in this blueprint, Project Hyperion can be engineered not just to function, but to thrive as a secure, transparent, and valuable component of the decentralized financial future.

#### **Referências citadas**

1. DeFi Crypto Margin Trading \- DeFi Short and Leveraged Trading Platforms \- DeFi Prime, acessado em julho 29, 2025, [https://defiprime.com/margin-trading](https://defiprime.com/margin-trading)  
2. GMX: Revolutionizing DeFi with Layer 2 Scaling, Governance, and ..., acessado em julho 29, 2025, [https://www.thestandard.io/blog/gmx-revolutionizing-defi-with-layer-2-scaling-governance-and-liquidity-innovation-in-2025-5](https://www.thestandard.io/blog/gmx-revolutionizing-defi-with-layer-2-scaling-governance-and-liquidity-innovation-in-2025-5)  
3. Best Decentralized Perpetuals Exchanges in 2025 \- Datawallet, acessado em julho 29, 2025, [https://www.datawallet.com/crypto/best-decentralized-perpetuals-exchanges](https://www.datawallet.com/crypto/best-decentralized-perpetuals-exchanges)  
4. Crypto Leverage Trading: What Is It & How It Works | Gemini, acessado em julho 29, 2025, [https://www.gemini.com/cryptopedia/crypto-leverage-trading](https://www.gemini.com/cryptopedia/crypto-leverage-trading)  
5. How to Trade DeFi Coins With Leverage? \- Delta Exchange, acessado em julho 29, 2025, [https://www.delta.exchange/blog/how-trade-defi-coins-with-leverage](https://www.delta.exchange/blog/how-trade-defi-coins-with-leverage)  
6. What is leverage trading in crypto? \- Kraken, acessado em julho 29, 2025, [https://www.kraken.com/learn/leverage-trading-crypto](https://www.kraken.com/learn/leverage-trading-crypto)  
7. Understanding Margin Trading: Benefits, Risks, and Key Insights \- Investopedia, acessado em julho 29, 2025, [https://www.investopedia.com/terms/m/margin.asp](https://www.investopedia.com/terms/m/margin.asp)  
8. Crypto Margin Trading: Investor's Guide 2025 \- CoinLedger, acessado em julho 29, 2025, [https://coinledger.io/learn/crypto-margin-trading](https://coinledger.io/learn/crypto-margin-trading)  
9. Introduction | Defactor Developer Docs, acessado em julho 29, 2025, [https://defactor.dev/docs/pools/smart-contracts/erc20-collateral-pool-contract/smart-contract-erc20-collateral-pool/](https://defactor.dev/docs/pools/smart-contracts/erc20-collateral-pool-contract/smart-contract-erc20-collateral-pool/)  
10. What Is Long/Short Trading In Crypto: A Complete Guide \- ZebPay, acessado em julho 29, 2025, [https://zebpay.com/blog/what-is-long-short-trading-strategy](https://zebpay.com/blog/what-is-long-short-trading-strategy)  
11. A Beginner's Guide to Margin Trading Crypto \- Gemini, acessado em julho 29, 2025, [https://www.gemini.com/cryptopedia/margin-trading-cryptocurrency](https://www.gemini.com/cryptopedia/margin-trading-cryptocurrency)  
12. www.ig.com, acessado em julho 29, 2025, [https://www.ig.com/en/trading-strategies/how-to-short-cryptocurrencies-230612\#:\~:text=excluding%20additional%20costs.-,Long%20vs%20short%20position%20in%20crypto,before%20the%20crypto%20price%20decreases.](https://www.ig.com/en/trading-strategies/how-to-short-cryptocurrencies-230612#:~:text=excluding%20additional%20costs.-,Long%20vs%20short%20position%20in%20crypto,before%20the%20crypto%20price%20decreases.)  
13. Long and Short Positions Explained \- LCX, acessado em julho 29, 2025, [https://www.lcx.com/long-and-short-positions-explained/](https://www.lcx.com/long-and-short-positions-explained/)  
14. medium.com, acessado em julho 29, 2025, [https://medium.com/@KineProtocol/kine-academy-2-peer-to-pool-vs-order-book-in-trading-9c995b3b351d\#:\~:text=Unlike%20traditional%20exchanges%20which%20rely,through%20the%20central%20liquidity%20pool.\&text=This%20model%20involves%20two%20counter,LPs)%20and%20perpetual%20contracts%20traders.](https://medium.com/@KineProtocol/kine-academy-2-peer-to-pool-vs-order-book-in-trading-9c995b3b351d#:~:text=Unlike%20traditional%20exchanges%20which%20rely,through%20the%20central%20liquidity%20pool.&text=This%20model%20involves%20two%20counter,LPs\)%20and%20perpetual%20contracts%20traders.)  
15. Perpetual Futures Contracts and Cryptocurrency Market Quality, acessado em julho 29, 2025, [https://business.cornell.edu/article/2025/02/perpetual-futures-contracts-and-cryptocurrency/](https://business.cornell.edu/article/2025/02/perpetual-futures-contracts-and-cryptocurrency/)  
16. What are Perpetual Futures? & How They Work \- Gemini, acessado em julho 29, 2025, [https://www.gemini.com/cryptopedia/what-are-perpetual-futures](https://www.gemini.com/cryptopedia/what-are-perpetual-futures)  
17. Perpetual Futures: What They Are and How They Work \- Investopedia, acessado em julho 29, 2025, [https://www.investopedia.com/what-are-perpetual-futures-7494870](https://www.investopedia.com/what-are-perpetual-futures-7494870)  
18. What are perpetual futures contracts? \- Kraken, acessado em julho 29, 2025, [https://www.kraken.com/learn/trading/perpetual-futures-contracts](https://www.kraken.com/learn/trading/perpetual-futures-contracts)  
19. Understanding Funding Rates in Perpetual Futures and Their Impact \- Coinbase, acessado em julho 29, 2025, [https://www.coinbase.com/en-gb/learn/perpetual-futures/understanding-funding-rates-in-perpetual-futures](https://www.coinbase.com/en-gb/learn/perpetual-futures/understanding-funding-rates-in-perpetual-futures)  
20. Understanding Funding Rates in Perpetual Futures and Their Impact ..., acessado em julho 29, 2025, [https://www.coinbase.com/learn/perpetual-futures/understanding-funding-rates-in-perpetual-futures](https://www.coinbase.com/learn/perpetual-futures/understanding-funding-rates-in-perpetual-futures)  
21. Funding Rates \- Amberdata API, acessado em julho 29, 2025, [https://docs.amberdata.io/docs/funding-rates-1](https://docs.amberdata.io/docs/funding-rates-1)  
22. Bitcoin-Perpetual Futures Funding Rate \- MacroMicro, acessado em julho 29, 2025, [https://en.macromicro.me/charts/49213/bitcoin-perpetual-futures-funding-rate](https://en.macromicro.me/charts/49213/bitcoin-perpetual-futures-funding-rate)  
23. Order Books vs. Liquidity Pools | CoinSpot, acessado em julho 29, 2025, [https://www.coinspot.com.au/learn/order-books-vs-liquidity-pools](https://www.coinspot.com.au/learn/order-books-vs-liquidity-pools)  
24. www.coinbase.com, acessado em julho 29, 2025, [https://www.coinbase.com/learn/advanced-trading/what-is-defi-liquidation\#:\~:text=DeFi%20liquidation%20is%20a%20process,the%20volatility%20of%20cryptocurrency%20values.](https://www.coinbase.com/learn/advanced-trading/what-is-defi-liquidation#:~:text=DeFi%20liquidation%20is%20a%20process,the%20volatility%20of%20cryptocurrency%20values.)  
25. DeFi Liquidation Protocols: How They Work \- Krayon, acessado em julho 29, 2025, [https://www.krayondigital.com/blog/defi-liquidation-protocols-how-they-work](https://www.krayondigital.com/blog/defi-liquidation-protocols-how-they-work)  
26. DeFi Lending: Liquidations and Collateral | By RareSkills – RareSkills, acessado em julho 29, 2025, [https://rareskills.io/post/defi-liquidations-collateral](https://rareskills.io/post/defi-liquidations-collateral)  
27. What Is Liquidation And How To Manage Liquidation Risk In Futures Trading | Mudrex Learn, acessado em julho 29, 2025, [https://mudrex.com/learn/crypto-futures-liquidation-explained/](https://mudrex.com/learn/crypto-futures-liquidation-explained/)  
28. guides.delta.exchange, acessado em julho 29, 2025, [https://guides.delta.exchange/delta-exchange-user-guide/trading-guide/margin-explainer/margin-explainer/liquidation\#:\~:text=Liquidation%20Price%3A%20At%20Liquidation%20Price,equal%20to%20the%20Position%20Margin.](https://guides.delta.exchange/delta-exchange-user-guide/trading-guide/margin-explainer/margin-explainer/liquidation#:~:text=Liquidation%20Price%3A%20At%20Liquidation%20Price,equal%20to%20the%20Position%20Margin.)  
29. What is Estimated Liquidation Price? \- Gemini Support, acessado em julho 29, 2025, [https://support.gemini.com/hc/en-us/articles/12087099122075-What-is-Estimated-Liquidation-Price](https://support.gemini.com/hc/en-us/articles/12087099122075-What-is-Estimated-Liquidation-Price)  
30. Liquidation of Isolated Margined Positions | Delta Exchange \- User Guide & Rule Book, acessado em julho 29, 2025, [https://guides.delta.exchange/delta-exchange-user-guide/trading-guide/margin-explainer/margin-explainer/liquidation](https://guides.delta.exchange/delta-exchange-user-guide/trading-guide/margin-explainer/margin-explainer/liquidation)  
31. How Liquidations Work in DeFi: A Deep Dive \- MixBytes, acessado em julho 29, 2025, [https://mixbytes.io/blog/how-liquidations-work-in-defi-a-deep-dive](https://mixbytes.io/blog/how-liquidations-work-in-defi-a-deep-dive)  
32. Top 10 Decentralized Crypto Exchanges (DEXs) to Watch in 2025, acessado em julho 29, 2025, [https://www.a3logics.com/blog/top-decentralized-crypto-exchanges/](https://www.a3logics.com/blog/top-decentralized-crypto-exchanges/)  
33. v4 Technical Architecture Overview \- dYdX, acessado em julho 29, 2025, [https://www.dydx.xyz/blog/v4-technical-architecture-overview](https://www.dydx.xyz/blog/v4-technical-architecture-overview)  
34. What is dYdX ? A Comprehensive Overview \- Imperator.co, acessado em julho 29, 2025, [https://www.imperator.co/resources/blog/what-is-dydx-blockchain-presentation](https://www.imperator.co/resources/blog/what-is-dydx-blockchain-presentation)  
35. Intro to dYdX Chain Architecture · dYdX · v4 \- dYdX Documentation, acessado em julho 29, 2025, [https://docs.dydx.exchange/concepts-architecture/architectural\_overview](https://docs.dydx.exchange/concepts-architecture/architectural_overview)  
36. \[Kine Academy\#2\] Peer-to-Pool vs Order Book in Trading | by Kine ..., acessado em julho 29, 2025, [https://medium.com/@KineProtocol/kine-academy-2-peer-to-pool-vs-order-book-in-trading-9c995b3b351d](https://medium.com/@KineProtocol/kine-academy-2-peer-to-pool-vs-order-book-in-trading-9c995b3b351d)  
37. What Is Synthetix & How Does It Work? Who Created SNX? \- Kriptomat, acessado em julho 29, 2025, [https://kriptomat.io/cryptocurrency-prices/synthetix-snx-price/what-is/](https://kriptomat.io/cryptocurrency-prices/synthetix-snx-price/what-is/)  
38. Foundation \- GMX Contract Architecture \- GMX Perpetuals ... \- Video, acessado em julho 29, 2025, [https://updraft.cyfrin.io/courses/gmx-perpetuals-trading/foundation/gmx-contract-architecture](https://updraft.cyfrin.io/courses/gmx-perpetuals-trading/foundation/gmx-contract-architecture)  
39. What Crypto Users Need to Know: The ERC20 Standard \- Investopedia, acessado em julho 29, 2025, [https://www.investopedia.com/tech/why-crypto-users-need-know-about-erc20-token-standard/](https://www.investopedia.com/tech/why-crypto-users-need-know-about-erc20-token-standard/)  
40. Everything I learned building my first DApp — a frontend perspective | by Dara Olayebi, acessado em julho 29, 2025, [https://coinsbench.com/everything-i-learnt-building-my-first-dapp-a-frontend-perspective-ba810be1493f](https://coinsbench.com/everything-i-learnt-building-my-first-dapp-a-frontend-perspective-ba810be1493f)  
41. DeFi-Developer-Road-Map/README.md at main · OffcierCia/DeFi ..., acessado em julho 29, 2025, [https://github.com/OffcierCia/DeFi-Developer-Road-Map/blob/main/README.md?plain=1](https://github.com/OffcierCia/DeFi-Developer-Road-Map/blob/main/README.md?plain=1)  
42. Best Practices for Writing Secure Smart Contract Code \- Nethermind ..., acessado em julho 29, 2025, [https://www.nethermind.io/blog/best-practices-for-writing-secure-smart-contract-code](https://www.nethermind.io/blog/best-practices-for-writing-secure-smart-contract-code)  
43. Smart Contracts Security: Best Practices Explained \- Webisoft, acessado em julho 29, 2025, [https://webisoft.com/articles/smart-contracts-security/](https://webisoft.com/articles/smart-contracts-security/)  
44. Collateralized ERC-20 Token \- GitHub, acessado em julho 29, 2025, [https://github.com/iluxonchik/collateralized-erc-20](https://github.com/iluxonchik/collateralized-erc-20)  
45. Ultimate Guide to Understand Role of Smart Contracts in DeFi \- Rapid Innovation, acessado em julho 29, 2025, [https://www.rapidinnovation.io/post/smart-contracts-and-defi-transforming-decentralized-finance](https://www.rapidinnovation.io/post/smart-contracts-and-defi-transforming-decentralized-finance)  
46. What are Oracles on Smart Contracts? \- Stellar, acessado em julho 29, 2025, [https://stellar.org/learn/smart-contract-basics-oracles](https://stellar.org/learn/smart-contract-basics-oracles)  
47. What Is an Oracle in Blockchain? » Explained | Chainlink, acessado em julho 29, 2025, [https://chain.link/education/blockchain-oracles](https://chain.link/education/blockchain-oracles)  
48. en.wikipedia.org, acessado em julho 29, 2025, [https://en.wikipedia.org/wiki/Blockchain\_oracle](https://en.wikipedia.org/wiki/Blockchain_oracle)  
49. DeFi Protocol Hacks: Understanding Security Risks and Solutions, acessado em julho 29, 2025, [https://www.startupdefense.io/cyberattacks/defi-protocol-hack](https://www.startupdefense.io/cyberattacks/defi-protocol-hack)  
50. Price Feeds \- Chainlink Documentation, acessado em julho 29, 2025, [https://docs.chain.link/data-feeds/price-feeds](https://docs.chain.link/data-feeds/price-feeds)  
51. Chainlink Data Feeds | Avalanche Builder Hub, acessado em julho 29, 2025, [https://build.avax.network/integrations/chainlink-data-feeds](https://build.avax.network/integrations/chainlink-data-feeds)  
52. Price Feed Contract Addresses | Chainlink Documentation, acessado em julho 29, 2025, [https://docs.chain.link/data-feeds/price-feeds/addresses](https://docs.chain.link/data-feeds/price-feeds/addresses)  
53. How to start building DApps \[duplicate\] \- Ethereum Stack Exchange, acessado em julho 29, 2025, [https://ethereum.stackexchange.com/questions/159969/how-to-start-building-dapps](https://ethereum.stackexchange.com/questions/159969/how-to-start-building-dapps)  
54. Integrate Your Smart Contract With a Frontend \- Web3 University, acessado em julho 29, 2025, [https://www.web3.university/tracks/create-a-smart-contract/integrate-your-smart-contract-with-a-frontend](https://www.web3.university/tracks/create-a-smart-contract/integrate-your-smart-contract-with-a-frontend)  
55. The Ultimate Ethereum Dapp Tutorial (How to Build a Full Stack Decentralized Application Step-By-Step) | Dapp University, acessado em julho 29, 2025, [https://www.dappuniversity.com/articles/the-ultimate-ethereum-dapp-tutorial](https://www.dappuniversity.com/articles/the-ultimate-ethereum-dapp-tutorial)  
56. Integrating your Smart Contract with Frontend \- GeeksforGeeks, acessado em julho 29, 2025, [https://www.geeksforgeeks.org/solidity/integrating-your-smart-contract-with-frontend/](https://www.geeksforgeeks.org/solidity/integrating-your-smart-contract-with-frontend/)  
57. DeFi Security: Protect Your Platform from Hacks \- Debut Infotech, acessado em julho 29, 2025, [https://www.debutinfotech.com/blog/defi-security-protect-platform-hacks-exploits](https://www.debutinfotech.com/blog/defi-security-protect-platform-hacks-exploits)