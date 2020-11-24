pragma solidity ^0.6.12;

// @title Distribution Trustee
// @author Jason Chroman
// @notice This is only a proof of concept. It is not ready for actual use with real money involved. 
// @dev All function calls are currently implemented without side effects


/* 
Bankruptcy Funds Distribution Example
--------------------------------------
The contract enables the distribution of funds according to a waterfall. 
The amounts in the waterfall are consistent with the Plan that was submitted to and approved by the court. 
Those amounts are specified here in the tiny amounts of wei for this proof of concept. 
In a real setting the amounts would be specified in currency or stablecoin: 

    Admin Fees:             60,000 wei
    Employee Salaries:     110,000 wei
    GovtTaxes:              65,000 wei
    Sr Secured Creditors:  120,000 wei
    Bondholders:            80,000 wei
    The Jr Creditors and the equity have agreed to split any remainder on a 60/40 basis.

The contract will first receive funds.  
The contract will only accept funds from the Liquidation Trustee, though anyone can send funds to it. 
The Admin Fees will be paid in full before any funds are distributed to cover Employee Salaries. 
Then Employee Salaries will be paid in full before any Govt Taxes are paid... and so on. 

After the Bondholders have received payment, funds will be split between the Jr Creditors and the Equity on a 60/40 basis. 

For simplicity, any funds received get paid out entirely.  The contract does not hold on to funds. 
*/



contract DistributionTrustee {
//====================================================================================================
//====================================================================================================
//
// 1000 - Initial Setup
//
//====================================================================================================
//====================================================================================================

    // 1. Global Variables
    uint256 public CumulativeReceivedBalance            = 0;
    uint256 public CumulativePaidOutBalance             = 0;
    uint256 public AmtReceived                          = 0; 

    // 1. Global Variables
    address payable public owner;
    uint256 ThisReceipt                                 = 0;

    // 2. Gas Tracking Variables
    uint256 AvailableGas                                = 0;
    uint256 DistributableGas                            = 0;
    uint256 GasTransferFee                              = 21000;


    // 3. The parties
    address payable  AdminFees                          = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address payable  EmployeeSalaries                   = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address payable  GovtTaxes                          = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address payable  SrSecuredCreditors                 = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
    address payable  Bondholders                        = 0x17F6AD8Ef982297579C203069C1DbfFE4348c372;
    address payable  JrCreditors                        = 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678;
    address payable  Equity                             = 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7;

    // 4. What each party is owed
    // a. Parties with fixed payouts
    uint256 exponentUnits                               = 15;     // at 3, this is a small amount of ETH. At 18, it's full ETH. 
    uint256 AdminFeesPriorityDistributionAmt            = 60*10**exponentUnits;     
    uint256 EmployeeSalariesPriorityDistributionAmt     = 110*10**exponentUnits;    
    uint256 GovtTaxesPriorityDistributionAmt            = 65*10**exponentUnits;     
    uint256 SrSecuredCreditorsPriorityDistributionAmt   = 120*10**exponentUnits;    
    uint256 BondholdersPriorityDistributionAmt          = 80*10**exponentUnits;     


    // b. Parties with variable payouts
    uint256 JrCreditorsShare                            = 60;
    uint256 EquityShare                                 = 40;
    uint256 units                                       = 100;


    // 5. Other Overhead

    //initialize AP Accts with zero balances
    uint256 public AdminFeesPayable                     = 0;
    uint256 public EmployeeSalariesPayable              = 0;
    uint256 public GovtTaxesPayable                     = 0;
    uint256 public SrSecuredCreditorsPayable            = 0;
    uint256 public BondholdersPayable                   = 0;
    uint256 public JrCreditorsPayable                   = 0;
    uint256 public EquityPayable                        = 0;

    
    uint256 public AdminFeesCumulPaid                   = 0;
    uint256 public EmployeeSalariesCumulPaid            = 0;
    uint256 public GovtTaxesCumulPaid                   = 0;
    uint256 public SrSecuredCreditorsCumulPaid          = 0;
    uint256 public BondholdersCumulPaid                 = 0;
    uint256 public JrCreditorsCumulPaid                 = 0;
    uint256 public EquityCumulPaid                      = 0;




    /* Fill in the keyword. Hint: We want to protect our users balance from other contracts*/
  //  mapping (address => uint) balances;
    mapping(address => uint) private balances;    

    /* Fill in the keyword. We want to create a getter function and allow contracts to be able to see if a user is enrolled.  */
    mapping (address => bool) public enrolled;

    /* Let's make sure everyone knows who owns the bank. Use the appropriate keyword for this*/
    // address public owner;
    

    //


    //
    // Functions
    //



//====================================================================================================
//====================================================================================================
//
// 1200 - Modifiers
//
//====================================================================================================
//====================================================================================================


modifier onlyOwner(address _address) { require(msg.sender == owner, "Only ContractOwner can make distributions."  ); _;}
// modifier gottaHaveGas() { require(AvailableGas >= 21000, "Can't make distributions. Out of Gas. Owner has to add Gas"  ); _;}


//====================================================================================================
//====================================================================================================
//
// 1300 - Enums, Event Logs, and Structs
//
//====================================================================================================
//====================================================================================================

//enum Stage {"Admin", "EmpSal", "Taxes", "Seniors", "Bondholders", "Juniors"}


//Events
event LogStage(address stage);
event LogReceipt(address sender, uint amt);
event LogEvent(uint stage, string stagedesc, uint amount);


//orig events 
event LogEnrolled(address accountAddress);  
event LogDepositMade(address accountAddress, uint amount);
event LogWithdrawal(address accountAddress, uint withdrawAmount, uint newBalance);


//Struct#1: Receipts - i.e. Amounts received by the contract
struct Receipt {
    uint receiptNum; 
    uint AmountReceived;
    address payable ReceivedFrom;
}
uint numPmtsReceived = 0;
mapping(uint256 => Receipt) public receipts;

//Struct#2: Payments - i.e. Amounts paid out by the contract
struct Distribution {
    uint distNum; 
    uint AmountPaid;
    address payable SentTo;
}
uint numDistributions = 0;
mapping(uint256 => Distribution) public distributions;


constructor() public {
    // The owner is the creator of this contract, which is the Distribution Trustee */
    owner = msg.sender;
}

    // Fallback function - Called if other functions don't match call or
    // sent ether without data
    // Typically, called when invalid data is sent
    // Added so ether sent to this contract is reverted if the contract fails
    // otherwise, the sender's money is transferred to contract
    
    fallback() external payable {
        revert();
    }
    
//====================================================================================================
//====================================================================================================
//
// 2000 - Calculate Waterfall Amounts
//
//====================================================================================================
//====================================================================================================

    function A_receivePmts() public payable returns (uint) {
        /* Add the amount to the user's balance, call the event associated with a deposit,
          then return the balance of the user */
        //   require(enrolled[msg.sender]);

        AmtReceived                                 += msg.value;           
        CumulativeReceivedBalance                   += AmtReceived;         

        emit LogReceipt(msg.sender, msg.value);                         
        P1_ProcessAdminFees();
        P2_ProcessEmployeeSalaries();
        P3_ProcessGovTaxes();
        P4_ProcessSrSecuredCreditors();
        P5_ProcessBondholders();
        P6_ProcessJrCreditorsAndEquity();

        return balances[msg.sender];                                        
    }    


    //Waterfall Level 1 - Admin Fees
    function P1_ProcessAdminFees() private {
        // uint256 AdminFeeIncrease                      = Math.min(AdminFeesPriorityDistributionAmt, AmtReceived); 
        uint256 AdminFeeIncrease                        = min(AdminFeesPriorityDistributionAmt, AmtReceived); 
        AdminFeesPayable                                += AdminFeeIncrease;
        AdminFeesPriorityDistributionAmt                -= AdminFeeIncrease; 
        AmtReceived                                     -= AdminFeeIncrease;
        if (AdminFeesPayable>0) {emit LogEvent(ThisReceipt, "Stage 1: Admin Fees Allocated", AdminFeesPayable);}
    }

    //Waterfall Level 2 - EmployeeSalaries
    function P2_ProcessEmployeeSalaries() private {
        // uint256 EmpSalIncrease                       = Math.min(EmployeeSalariesPriorityDistributionAmt, AmtReceived);
        uint256 EmpSalIncrease                          = min(EmployeeSalariesPriorityDistributionAmt, AmtReceived);
        EmployeeSalariesPayable                         += EmpSalIncrease; 
        EmployeeSalariesPriorityDistributionAmt         -= EmpSalIncrease; 
        AmtReceived                                     -= EmpSalIncrease;
        if (EmployeeSalariesPayable>0) {emit LogEvent(ThisReceipt, "Stage 2: EmployeeSalaries Allocated", EmployeeSalariesPayable);}
    }

    //Waterfall Level 3 - GovtTaxes
    function P3_ProcessGovTaxes() private {
        uint256 GovTaxIncrease                          = min(GovtTaxesPriorityDistributionAmt, AmtReceived);
        GovtTaxesPayable                                += GovTaxIncrease; 
        GovtTaxesPriorityDistributionAmt                -= GovTaxIncrease; 
        AmtReceived                                     -= GovTaxIncrease;
        if (GovtTaxesPayable>0) {emit LogEvent(ThisReceipt, "Stage 3; GovtTaxes Allocated", GovtTaxesPayable);}
    }

    //Waterfall Level 4 - SrSecuredCreditors
    function P4_ProcessSrSecuredCreditors() private {
        uint256 SrSecuredIncrease                       = min(SrSecuredCreditorsPriorityDistributionAmt, AmtReceived);
        SrSecuredCreditorsPayable                       += SrSecuredIncrease; 
        SrSecuredCreditorsPriorityDistributionAmt       -= SrSecuredIncrease; 
        AmtReceived                                     -= SrSecuredIncrease;
        if (SrSecuredCreditorsPayable>0) {emit LogEvent(ThisReceipt, "Stage 4: SeniorSecureds Allocated", SrSecuredCreditorsPayable);}
    }

    //Waterfall Level 5 - Bondholders
    function P5_ProcessBondholders() private {
        uint256 BondholdersIncrease                     = min(BondholdersPriorityDistributionAmt, AmtReceived);
        BondholdersPayable                              += BondholdersIncrease; 
        BondholdersPriorityDistributionAmt              -= BondholdersIncrease; 
        AmtReceived                                     -= BondholdersIncrease;
        if (BondholdersPayable>0) {emit LogEvent(ThisReceipt, "Stage 5: Bondholders Allocated", BondholdersPayable);}
    }

    //Waterfall Level 6 - Jr Creditors & Equity
    function P6_ProcessJrCreditorsAndEquity() private {
        // SafeMath didn't work properly in Remix
        // uint256 JrCreditorsIncrease                  = SafeMath.mul(AmtReceived, SafeMath.div(JrCreditorsShare,units)); 
        // uint256 EquityIncrease                       = SafeMath.mul(AmtReceived, SafeMath.div(EquityShare, units)); 
        uint256 JrCreditorsIncrease                     = AmtReceived * JrCreditorsShare / units; 
        uint256 EquityIncrease                          = AmtReceived * EquityShare / units; 
        JrCreditorsPayable                              += JrCreditorsIncrease; 
        EquityPayable                                   += EquityIncrease; 
        AmtReceived                                     -= JrCreditorsIncrease;
        AmtReceived                                     -= EquityIncrease;
        if (JrCreditorsPayable>0) {emit LogEvent(ThisReceipt, "Stage 6: JuniorCreditors Allocated", JrCreditorsPayable);}
        if (EquityPayable>0) {emit LogEvent(ThisReceipt, "Stage 6: Equity Allocated", JrCreditorsPayable);}
    }






//====================================================================================================
//====================================================================================================
//
// 3000 - Make Payouts
//
//====================================================================================================
//====================================================================================================

// @notice This is the primary "traffic cop" for distributing funds that have been allocated to the parties 
// @dev To save gas, subfunctions are called to make the payouts, but only if there is a payout to make. 
    function D_makeDistributions() payable public onlyOwner(msg.sender) {
        if(AdminFeesPayable>0)                          {D1_distributeToAdminFees();}
        if(EmployeeSalariesPayable>0)                   {D2_distributeToEmployeeSalaries();}
        if(GovtTaxesPayable>0)                          {D3_distributeToGovtTaxes();}
        if(SrSecuredCreditorsPayable>0)                 {D4_distributeToSrSecuredCreditors();}
        if(BondholdersPayable>0)                        {D5_distributeToBondholders();}
        if(JrCreditorsPayable>0)                        {D6_distributeToJrCreditors();}
        if(EquityPayable>0)                             {D7_distributeToEquity();}
    }

    function D1_distributeToAdminFees() payable public  {
        CumulativePaidOutBalance                        += AdminFeesPayable;
        AdminFeesCumulPaid                              += AdminFeesPayable;
        distributePayments(AdminFeesPayable, AdminFees);

        emit LogEvent(ThisReceipt, "Stage 1B: Admin Fees Paid", AdminFeesPayable);
        AdminFeesPayable                                = 0;
    }

    function D2_distributeToEmployeeSalaries() payable public  {
        CumulativePaidOutBalance                        += EmployeeSalariesPayable;
        EmployeeSalariesCumulPaid                       += EmployeeSalariesPayable;
        distributePayments(EmployeeSalariesPayable, EmployeeSalaries);

        emit LogEvent(ThisReceipt, "Stage 2B: EmployeeSalaries Paid", AdminFeesPayable);
        EmployeeSalariesPayable                         = 0;
    }
    function D3_distributeToGovtTaxes() payable public  {
        CumulativePaidOutBalance                        += GovtTaxesPayable;
        GovtTaxesCumulPaid                              += GovtTaxesPayable;
        distributePayments(GovtTaxesPayable, GovtTaxes);

        emit LogEvent(ThisReceipt, "Stage 3B: GovtTaxes Paid", AdminFeesPayable);
        GovtTaxesPayable                                = 0;
    }
    function D4_distributeToSrSecuredCreditors() payable public  {
        CumulativePaidOutBalance                        += SrSecuredCreditorsPayable;
        SrSecuredCreditorsCumulPaid                     += SrSecuredCreditorsPayable;
        distributePayments(SrSecuredCreditorsPayable, SrSecuredCreditors);

        emit LogEvent(ThisReceipt, "Stage 4B: SeniorSecureds Paid", AdminFeesPayable);
        SrSecuredCreditorsPayable                       = 0;
    }
    function D5_distributeToBondholders() payable public  {
        CumulativePaidOutBalance                        += BondholdersPayable;
        BondholdersCumulPaid                            += BondholdersPayable;
        distributePayments(BondholdersPayable, Bondholders);

        emit LogEvent(ThisReceipt, "Stage 5B: Bondholders Paid", AdminFeesPayable);
        BondholdersPayable                              = 0;
    }
    function D6_distributeToJrCreditors() payable public  {
        CumulativePaidOutBalance                        += JrCreditorsPayable;
        JrCreditorsCumulPaid                            += JrCreditorsPayable;
        distributePayments(JrCreditorsPayable, JrCreditors);

        emit LogEvent(ThisReceipt, "Stage 6B: JuniorCreditors Paid", AdminFeesPayable);
        JrCreditorsPayable                              = 0;
    }
    function D7_distributeToEquity() payable public  {
        CumulativePaidOutBalance                        += EquityPayable;
        EquityCumulPaid                                 += EquityPayable;
        distributePayments(EquityPayable, Equity);

        emit LogEvent(ThisReceipt, "Stage 7B: Equity Paid", AdminFeesPayable);
        EquityPayable                                   = 0;
    }

    function returnGas() payable public onlyOwner(msg.sender) {
        DistributableGas                                = AvailableGas - GasTransferFee; 
        distributePayments(DistributableGas , owner);
        AvailableGas                                    -= DistributableGas;
    }


// @notice This function below is called by the functions above for making payouts. 
// @dev Funds can only leave the contract thru this function. 
// @param The function is called with an amount to pay and the address of a party to be paid. 
// @return QUESTION: Nothing is returned.  Should it return a booolean TRUE if successful and FALSE if unsuccessful?  

    function distributePayments(uint256 Amt, address payable PartyToPay ) payable public {
        PartyToPay.transfer(Amt);  
        distributions[numDistributions] = Distribution({distNum: numDistributions, AmountPaid: Amt, SentTo: PartyToPay });
        numDistributions                                += 1;
        AvailableGas                                    -= AvailableGas - GasTransferFee; 
        DistributableGas                                = AvailableGas; 

    }


//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------
//  9000 - Add Ins
//---------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------

   //Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

}


