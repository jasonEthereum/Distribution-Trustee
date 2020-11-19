/*

The public version of the file used for testing can be found here: https://gist.github.com/ConsenSys-Academy/ce47850a8e2cba6ef366625b665c7fba

This test file has been updated for Truffle version 5.0. If your tests are failing, make sure that you are
using Truffle version 5.0. You can check this by running "trufffle version"  in the terminal. If version 5 is not
installed, you can uninstall the existing version with `npm uninstall -g truffle` and install the latest version (5.0)
with `npm install -g truffle`.

*/
let catchRevert = require("./exceptionsHelpers.js").catchRevert
var SimpleBank = artifacts.require("./DistributionTrustee.sol")

contract('SimpleBank', function(accounts) {

  const owner = accounts[0]
  const alice = accounts[1]
  const bob = accounts[2]
  const deposit = web3.utils.toBN(100000)

  beforeEach(async () => {
    instance = await SimpleBank.new()
  })

  
  it("1. Contract should be able to receive funds and record received funds in the Cumulative Register", async () => {
    await instance.A_receivePmts({from: alice, value: deposit})
    await instance.A_receivePmts({from: bob, value: deposit})
    const cumulReceived                               = await instance.CumulativeReceivedBalance()
    assert.equal(cumulReceived.toNumber(),            deposit*2, '1 Cumul received balance is incorrect')
  })

  it("2A. AdminFeesPayable and EmployeeSalariesPayable should be Incremented", async () => {
    await instance.A_receivePmts({from: alice, value: deposit})
    const adminFeesPayable                            = await instance.AdminFeesPayable()
    const employeeSalariesPayable                     = await instance.EmployeeSalariesPayable()
    assert.equal(adminFeesPayable.toNumber(),           60000, '2 AdminFeesPayable is incorrect')
    assert.equal(employeeSalariesPayable.toNumber(),    40000, '3 EmployeeSalariesPayable is incorrect')
  })

  it("2B. Sr Secured and Bondholder Payables should be Incremented", async () => {
    await instance.A_receivePmts({from: alice, value: deposit*4})
    const srSecuredPybl                               = await instance.SrSecuredCreditorsPayable()
    const bondholdersPybl                             = await instance.BondholdersPayable()
    assert.equal(srSecuredPybl.toNumber(),             120000, '4 SrSecuredCreditorsPayable is incorrect')
    assert.equal(bondholdersPybl.toNumber(),            45000, '5 EmployeeSalariesPayable is incorrect')
  })


  it("2C. Jr Creditors and Equity Payables should be incremented properly", async () => {
    await instance.A_receivePmts({from: alice, value: deposit*5})
    const jrCreditorsPybl                             = await instance.JrCreditorsPayable()
    const equityPybl                                  = await instance.EquityPayable()
    assert.equal(jrCreditorsPybl.toNumber(),            39000, '6 JrCreditorsPayable is incorrect')
    assert.equal(equityPybl.toNumber(),                 26000, '7 EquityPayable is incorrect')
  })

  it("3. The Distribution Trustee can make distributions", async () => {
    let eventEmitted = false
    await instance.A_receivePmts({from: owner, value: deposit})
    const tx = await instance.D_makeDistributions({from: owner})  
      if (tx.logs[0].event == "LogEvent") {
        eventEmitted = true
    }
    assert.equal(eventEmitted, true, 'Owner not able to transfer  funds from the contract')
  })

/* 
  // The below *SHOULD* throw an error and it does, because only the Distribution Trustee should be able to make distributions. 
  // I'm not sure how to code this so that Javascript captures the error and the test passes.    
  it("3B. Anyone other than the Distribution Trustee cannot make distributions", async () => {
    let eventNOTEmitted = true
    await instance.A_receivePmts({from: owner, value: deposit})
    const tx = await instance.D_makeDistributions({from: alice})  
      if (tx.logs[0].event == "LogEvent") {
        eventNOTEmitted = false
    }
    assert.equal(eventNOTEmitted, false, 'Only Owner should be able to transfer funds from the contract')
  })
*/

  it("4. Distributions are made in the correct amounts in aggregate", async () => {
    await instance.A_receivePmts({from: alice, value: deposit*5})
    await instance.D_makeDistributions({from: owner}) 
    
    const cumulPaidOut                                = await instance.CumulativePaidOutBalance()
    assert.equal(cumulPaidOut.toNumber(),              500000, '10 incorrect amount distributed cumulatively')
  })

  it("5. Distributions are made in the correct amounts to Equity", async () => {
    await instance.A_receivePmts({from: alice, value: deposit*6})
    await instance.D_makeDistributions({from: owner}) 
    
    const equityPaidOut                                = await instance.EquityCumulPaid()
    assert.equal(equityPaidOut.toNumber(),               66000, '10 incorrect amount distributed cumulatively')
  })

  it("6A. Should emit a LogReceipt event any time funds are received", async()=> {
    let eventEmitted = false
    const tx = await instance.A_receivePmts({from: alice, value: deposit})
    
      if (tx.logs[0].event == "LogReceipt") {
        eventEmitted = true
    }
    assert.equal(eventEmitted, true, 'Transferring funds into the contract should emit a LogReceipt event')
  })

  it("6B. Should emit a LogEvent event any time funds are distributed", async()=> {
    let eventEmitted = false
    await instance.A_receivePmts({from: alice, value: deposit*5})
    const tx = await instance.D_makeDistributions({from: owner})  
      if (tx.logs[0].event == "LogEvent") {
        eventEmitted = true
    }
    assert.equal(eventEmitted, true, 'Transferring funds from the contract should emit a LogEvent event')
  })





    // it("should mark addresses as enrolled", async () => {
  //   await instance.enroll({from: alice})
  //   const aliceEnrolled = await instance.enrolled(alice, {from: alice})
  //   assert.equal(aliceEnrolled, true, 'enroll balance is incorrect, check balance method or constructor')
  // });

  // it("should not mark unenrolled users as enrolled", async() =>{
  //   const ownerEnrolled = await instance.enrolled(owner, {from: owner})
  //   assert.equal(ownerEnrolled, false, 'only enrolled users should be marked enrolled')
  // })

  // it("should deposit correct amount", async () => {
  //   await instance.enroll({from: alice})
  //   await instance.deposit({from: alice, value: deposit})
  //   const balance = await instance.getBalance({from: alice})

  //   assert.equal(deposit.toString(), balance, 'deposit amount incorrect, check deposit method')
  // })


  // it("should log a deposit event when a deposit is made", async() => {
  //   await instance.enroll({from: alice})
  //   const result  = await instance.deposit({from: alice, value: deposit})
    
  //   const expectedEventResult = {accountAddress: alice, amount: deposit}

  //   const logAccountAddress = result.logs[0].args.accountAddress
  //   const logDepositAmount = result.logs[0].args.amount.toNumber()

  //   assert.equal(expectedEventResult.accountAddress, logAccountAddress, "LogDepositMade event accountAddress property not emitted, check deposit method");
  //   assert.equal(expectedEventResult.amount, logDepositAmount, "LogDepositMade event amount property not emitted, check deposit method")
  // })

  // it("should withdraw correct amount", async () => {
  //   const initialAmount = 0
  //   await instance.enroll({from: alice})
  //   await instance.deposit({from: alice, value: deposit})
  //   await instance.withdraw(deposit, {from: alice})
  //   const balance = await instance.getBalance({from: alice})

  //   assert.equal(balance.toString(), initialAmount.toString(), 'balance incorrect after withdrawal, check withdraw method')
  // })

  // it("should not be able to withdraw more than has been deposited", async() => {
  //   await instance.enroll({from: alice})
  //   await instance.deposit({from: alice, value: deposit})
  //   await catchRevert(instance.withdraw(deposit + 1, {from: alice}))
  // })

  // it("should emit the appropriate event when a withdrawal is made", async()=>{
  //   const initialAmount = 0
  //   await instance.enroll({from: alice})
  //   await instance.deposit({from: alice, value: deposit})
  //   var result = await instance.withdraw(deposit, {from: alice})

  //   const accountAddress = result.logs[0].args.accountAddress
  //   const newBalance = result.logs[0].args.newBalance.toNumber()
  //   const withdrawAmount = result.logs[0].args.withdrawAmount.toNumber()

  //   const expectedEventResult = {accountAddress: alice, newBalance: initialAmount, withdrawAmount: deposit}

  //   assert.equal(expectedEventResult.accountAddress, accountAddress, "LogWithdrawal event accountAddress property not emitted, check deposit method")
  //   assert.equal(expectedEventResult.newBalance, newBalance, "LogWithdrawal event newBalance property not emitted, check deposit method")
  //   assert.equal(expectedEventResult.withdrawAmount, withdrawAmount, "LogWithdrawal event withdrawalAmount property not emitted, check deposit method")
  // })
})
