const { assert } = require("chai");
const DigitalGolems = artifacts.require("DigitalGolems");
// const { assert } = require('chai')
const {
    catchRevert,            
    catchOutOfGas,          
    catchInvalidJump,       
    catchInvalidOpcode,     
    catchStackOverflow,     
    catchStackUnderflow,   
    catchStaticStateChange
} = require("../utils/catch_error.js")

contract('DigitalGolems', async (accounts)=>{ 
    const secondsInADay = 86400;
    let instance;
    const owner = accounts[0]
    const player1 = accounts[9]
    const player2 = accounts[8]
    const tokenURIs = [
        "https://ipfs.io/ipfs/QmUdTP3VBY5b9u1Bdc3AwKggQMg5TQyNXVfzgcUQKjdmRH",
        "https://ipfs.io/ipfs/QmQ4SmLdMF64B1nVRVTGHEYcQUnv3tXFqfy5hZNSKXUdDY",
        "https://ipfs.io/ipfs/QmVZFZfzgf9aE3wQKSq6yG9aQMo6kSSGittYy1yp1u4Urr"
    ]
    const kinds = [1, 2, 3]
    const series = [1, 2, 3]

    before(async () => {
        instance = await DigitalGolems.deployed()
    })

    it("Owner Should mint 3 nft", async ()=> {
        const randomNum = Math.ceil(Math.random() * 10**16);
        //mint from owner 3 nft
        for (let i = 0; i < tokenURIs.length; i++) {
            await instance.ownerMint(
                player1,
                tokenURIs[i],
                kinds[i],
                series[i],
                {from: owner}
            )
        }
        const balancePlayer1 = (await instance.balanceOf(player1)).toString()
        const balanceCardPlayer1 = (await instance.cardCount(player1)).toString()
        //check if player realy have nft and cards
        assert.equal(
            (tokenURIs.length).toString(),
            balancePlayer1
        )
        assert.equal(
            (tokenURIs.length).toString(),
            balanceCardPlayer1
        )
        //can uncomment to see
        const amountNum = 
            (await instance.getAmountOfNumAbilities()).toString()
        const amountBool = 
            (await instance.getAmountOfBoolAbilities()).toString()
            // console.log(amountBool)
        console.log("Integer abilities")
        for (let i = 0; i < amountNum; i++) {
            console.log(
                "ID:", 
                i,
                "Int:",
                (await instance.getNumAbilityInt(3, i)).toString()
                )
        }
        console.log("Bool abilities")
        for (let i = 0; i < amountBool; i++) {
            console.log(
                "ID:", 
                i,
                "Bool:",
                (await instance.getBoolAbilityBool(3, i)).toString()
                )
        }
    })

    it("Should be error, cause mint not owner", async () => {
        const randomNum = Math.ceil(Math.random() * 10**16);
        //will be error 'cause this is not owner
        for (let i = 0; i < tokenURIs.length; i++) {
            catchRevert(instance.ownerMint(
                player1,
                tokenURIs[i],
                kinds[i],
                series[i],
                {from: player1}
            ))
        }
        const balancePlayer2 = (await instance.balanceOf(player2)).toString()
        //check if realy didnt mint
        assert.equal(
            (0).toString(),
            balancePlayer2
        )
    })

    it("Should transfer golem", async ()=>{
        //checks if with nft transfer card transfer too
        await instance.transferFrom(player1, player2, 1, {from: player1})
        const newOwnerNFT = await instance.ownerOf(1)
        const newOwnerCard = await instance.cardOwner(1)
        assert.equal(
            newOwnerNFT,
            player2
        )
        assert.equal(
            newOwnerCard,
            player2
        )
    })

})