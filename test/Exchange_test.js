const Exchange = artifacts.require('./Exchange.sol') ;
const SPOTICTOKEN = artifacts.require('./SPOTICTOKEN.sol') ;

require('chai')
    .use(require('chai-as-promised'))
    .should() ;

contract('Exchange Contract', async (accounts) => {
    let exchange ;

    before(async () => {
        let spoticToken = await SPOTICTOKEN.deployed() ;

        exchange = await Exchange.deployed([
            spoticToken.address
        ]);
    });

    it('Exchange' , async() => {
        await exchange.setExchangeRate(4000);
        
        let new_exchange_rate = await exchange.getExchangeRate();

        console.log(new_exchange_rate.toString());
    });
});
