# Gigante Rental Cars Liquidation and Distribution Summary 

Gigante is the largest rental car company in South America, with multiple offices spread across many Latin American countries. Unfortunately, a series of misfortunes has caused Gigante to enter bankruptcy.  Since credit is not available for a restructuring the court has accepted the liquidation plan submitted by the creditors. 

Under the liquidation plan, there will be two key parties which will act under the supervision of the court and the primary bankruptcy trustee. 

The Liquidation Trustee will oversee the sales of all of the Company’s assets.
The Distribution Trustee will oversee the distribution of the liquidation proceeds to the Company’s creditors, according to a plan that will be submitted to the court in the next several weeks as the Proof of Claim forms are submitted by the creditors and evaluated by the staff. 

The liquidation process is expected to take several months. Proceeds from liquidations are to be transferred into the Liquidation Trustee’s account.  After review of the liquidation proceeds and process, the Primary Bankruptcy Trustee will direct the Liquidation Trustee to transfer funds to the Distribution Trustee.  Upon receipt of funds, the Distribution Trustee will dispense funds to the creditor groups, according to the plan approved by the court. 



### Liquidation Trustee
---

The Liquidation Trustee has hired Auction Agents in multiple countries to run auctions of Gigante’s vehicle’s and other assets. Sale proceeds will be transferred by each Auction Agent to the Liquidation Trustee’s smart contract. Once funds are transferred to the Liquidation Trustee, funds can only be released to the Distribution Trustee. The Bankruptcy Trustee will oversee all transfers. 

(Note: This repository does not include the Liquidation Trustee) 

### Distribution Trustee
---

The Distribution Trustee will handle making payments to each class of creditors. Funds will be transferred from the Distribution Trustee to one of six subsidiary smart contracts for further disbursement among the individual creditors. 

The priority of claims that the Distribution Trustee will adhere to is as follows: 
1. Administrative Fees - 60,000
2. Salaries owed to employees - 110,000
3. Taxes - 65,000
4. Senior Secured Creditors - 120,000
5. Bondholders -800,000
6. The Junior Creditors and the equity have agreed to split any remainder on a 60/40 basis. 

For the purposes of this demonstration of the initial concept, the above amounts are specified in terms of we.  In a real setting, the amounts might refer to millions of dollars. 





### Implementation Mechanics
---

he Bankruptcy Court and the Trustee agree on the importance of transparency in the liquidation and distribution process. To that end, they have engaged BlockHeads LLC to implement the appropriate smart contracts and business processes to ensure the efficient resolution of this matter.   

The distribution of funds is the more difficult and more interesting part of the problem, so we focused on this part. 

Although the contract is designed to allow for funds to only be receivable from the Liquidation Trustee, as a practical matter, it makes more sense NOT to enshrine that concept in code. As such, the contract should receive funds from anyone. As part of testing, we will ensure that: 

* Funds are received properly by the contract, 
* Funds flow out based on priority, with the correct amounts are going to each party
* Funds are held for distribution until the DT calls for distribution. 
* The DT to send funds to himself OR to the payees, so as to ensure that funds never get stuck in the contract if, for whatever reason, a payee loses access to their wallet. 

All funds received by the contract are paid out to the parties *EXCEPT* funds sent by the owner.  That Ether is reserved as gas for the contract. (The alternative to this is to withhold 21000 wei from each payout, which is awkward).  The implication of this is that the contract *can* run out of gas.  The contract will be funded by the owner.  This differs from how the Liquidation Trustee contract handles gas, and the inconsistency is only because I want to be confident I can make it work either way. 

#### Gas treatment
Generally, any funds sent to the contract will be credited to the payees.  However, funds sent to the contract by the owner of the contract are for gas and will not be credited to the payees. 

#### Multi-sig wallet
In this demo, the Distribution Trustee is a single person.  A more advanced implementation would have those keys shared among several people in the form of a multi-signature wallet.  

We assume that each of the recipients receiving funds is a multi-sig wallet. 

## Timeline for Distribution Trustee Initial Development
___

| Phase  | Description           | Status  |
| ------ |:-------------:| -----:|
| 1      | Write Distribution Trustee | ok |
| 2      | Write Test Plan      |   ok |
| 3      | Deploy Distribution Trustee to Rinkeby      |  ok |






