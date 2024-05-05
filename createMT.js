
const { ethers } = require("ethers");
const {MerkleTree} = require('merkletreejs')
const keccak256 = require('keccak256')


//  https://juejin.cn/post/7138668382231986206


let data = [
    ['0x6A6AF8c1157b179e5cdeB0dF54e96200516Fe195', ethers.utils.parseEther('1')],
    ['0x48402530d59B99966f6e277854856f166cb92018', ethers.utils.parseEther('3')],
    ['0x75915368b2e48Ad464c7b22afAFeF517dEcF29B2', ethers.utils.parseEther('2')],
]

let datasolpack = data.map(item => ethers.utils.solidityPack(['address', 'uint256'], item))  // abi.encodePacked
console.log(datasolpack)


// buffer leaf nodes
const leafNodes = datasolpack.map(item => keccak256(item))

// new merkle tree
const merkleTree = new MerkleTree(leafNodes, keccak256)
const rootHash = merkleTree.getRoot()
// console.log('merkle root', rootHash.toString('hex'))
console.log('merkletree\n', merkleTree.toString())


// verify address1 and get hex proof
const verify1 = leafNodes[0]
const hexProof = merkleTree.getHexProof(verify1)
console.log('hetxProof', hexProof)
