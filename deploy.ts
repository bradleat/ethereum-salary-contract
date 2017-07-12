import * as fs from 'fs';
import * as net from 'net';
import * as Web3 from 'web3';
import * as abi from 'ethereumjs-abi';
import * as promisify from 'es6-promisify';
import * as inquirer from 'inquirer';


const client = new net.Socket();
const web3 = new Web3(new Web3.providers.IpcProvider('/Users/bradley/Library/Ethereum/geth.ipc', client));


// class Web3A {
//     private internalWeb3;
//     constructor(...args){
//         this.internalWeb3 = new Web3(...args);
//     }
// }

const getAccounts = promisify(web3.eth.getAccounts) as () => Promise<string[]>;
const unlockAccount = promisify(web3.personal.unlockAccount) as (
    account: string, password: string, unlockTime?: number
) => Promise<boolean>;

function deploy(contract, account, ...params): Promise<any>{
    return new Promise((resolve, reject) => {
        const deployedContract = contract.new(
            ...params,
            {
                from: account,
                gas: 4000000,
                data: `0x${fs.readFileSync('./build/contracts/salary.sol:SalarySplitAgreement.bin', 'utf8')}`
            },
            (err, res) => {
                if(err) {
                    reject(err);
                }
                else if(res.address){
                    resolve(res);
                }
            }
        );
    });

}

async function main(){
    const {accountPassword} = await inquirer.prompt([{
        type: 'password',
        name: 'accountPassword',
        message: 'Enter your ethereum account password to deploy the contract.'
    }]);
    const [myAccount] = await getAccounts();
    console.log(myAccount);

    const status = await unlockAccount(myAccount, accountPassword);
    console.log(status);

    const salaryContract = web3.eth.contract(
        JSON.parse(fs.readFileSync('./build/contracts/salary.sol:SalarySplitAgreement.abi', 'utf8'))
    );
    const antContractAddress = '0x960b236A07cf122663c4303350609A66A7B288C0'; // mainnet
    // const antContractAddress = '0x7f031d23e3d10a2dc40bcf8a36bf15a83a2ec5bb'; // testnet
    const deployedContract = await deploy(salaryContract, myAccount, antContractAddress);
    console.log(deployedContract.address);
    console.log(abi.rawEncode(["address"], [antContractAddress]).toString('hex'));

    // console.log(deployedContract);
    process.exit(0);
}

main();
