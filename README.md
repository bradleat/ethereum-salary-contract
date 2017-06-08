# Instructions

This guide assumes that you have Node.JS and the `yarn` package manager are installed.

Furthermore, for the deploy command requires `Mist` to be intalled and running either the mainnet or the testnet (ropsten).

Important commands:

1. `yarn` will install all other necessary packages
2. `yarn build` will build the deployment code and the contract code
3. `yarn deploy` will deploy the contract to whatever network `Mist` is currently using.

Testing Guide:

1. Ensure that the variable `const antContractAddress` on line 63 of `deploy.ts` is set to an address of an ERC token you wish to use as the ANT token. (rebuild if this needs to change)

2. After deploying the contract to the mainnet and using `build/contracts/salary.sol:SalarySplitAgreement.abi` as the ABI for `Mist` try out the following:

- send Ether and some ANT token (the same token from step 1) to the contract. This will be used to pay any outstanding salaries
- make a salary proposal using the `Propose Salary` function
- accept this proposal from an employee address using the `Accept Salary Function`
- notice the `Balance payable (eth | usd | ant)` amount update for the employee address daily
- at an interval of your choosing you can call the `Trigger Payment` function to close out the account

Notice how the employer can call the `Terminate Contract` function and the employee can call the `Quit` function.
Both of these functions will update the contract in a state where the next `Trigger Payment` will stop the `Balance payable` amount from updated further (meaning the contract is finished).

Notice how an event is created noting that a certain USD dollar payment is owed.




