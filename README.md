# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat compile


npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
npx hardhat run scripts/deploy.ts --network localhost
npx hardhat run scripts/deploy.ts --network hsk_testnet

npx hardhat verify --network hsk_testnet 0xbE6cAD380f232d848C788d2d7D65DC9A50d2eCC3 "1000000000000", "Tether USD", "USDT", 6
```

```shell
polygon mumbai:
USDT: [0xE36e88dad95EE1100638956dED986Cb77dDF1747](https://mumbai.polygonscan.com/address/0xE36e88dad95EE1100638956dED986Cb77dDF1747)
ERC1155Asteroid: [0xCcDC4B2D2E8849c6248B43ba30FEa6DF9bA3B829](https://mumbai.polygonscan.com/address/0xCcDC4B2D2E8849c6248B43ba30FEa6DF9bA3B829)
LaunchPadAsteroid: [0xFD451722F1467309dAcebf5B299Cdbf1E01430AE](https://mumbai.polygonscan.com/address/0xFD451722F1467309dAcebf5B299Cdbf1E01430AE)

ERC1155Asteroid#grantRole
para1: 0x9e37095ee9b77171bf9351b5bf50a9f4803be693d3445664940ad3109c59b80c
para2(LaunchPadAsteroid contract): 0xFD451722F1467309dAcebf5B299Cdbf1E01430AE

LaunchPadAsteroid#setERC1155AsteroidContract
para1(ERC1155Asteroid contract): 0xCcDC4B2D2E8849c6248B43ba30FEa6DF9bA3B829

bnb testnet:
USDT: [0x4E8993CeEd3acCA99F63DD56e15256b416ec3D53](https://testnet.bscscan.com/address/0x4E8993CeEd3acCA99F63DD56e15256b416ec3D53)
ERC1155Asteroid: [0x3fFa7E317BFa85806274ca63387B3c4053077B09](https://testnet.bscscan.com/address/0x3fFa7E317BFa85806274ca63387B3c4053077B09)
LaunchPadAsteroid: [0x427DdFcC4A19EF5a7dd20507569fc94898beB900](https://testnet.bscscan.com/address/0x427ddfcc4a19ef5a7dd20507569fc94898beb900)

ERC1155Asteroid#grantRole
para1: 0x9e37095ee9b77171bf9351b5bf50a9f4803be693d3445664940ad3109c59b80c
para2(LaunchPadAsteroid contract): 0x427DdFcC4A19EF5a7dd20507569fc94898beB900

LaunchPadAsteroid#setERC1155AsteroidContract
para1(ERC1155Asteroid contract): 0x3fFa7E317BFa85806274ca63387B3c4053077B09

bnb && polygon create asset:
ERC1155Asteroid#create
para1(_initialOwner): 0xcF93c8935F1c40b7851697b36AB92B6Be0aFd24F
para2(_id): 100
para3(_initialSupply): 20000
para4(_initialRaisedAmounts): 1000000
para5(_initialMinAmount): 50
para6(_initialMaxAmount): 200
para7(_initialFundsWallet): 0xcF93c8935F1c40b7851697b36AB92B6Be0aFd24F
para8(_uri): ""
para9(_data): 0x00

ERC1155Asteroid#create
para1(_initialOwner): 0xcF93c8935F1c40b7851697b36AB92B6Be0aFd24F
para2(_id): 101
para3(_initialSupply): 20000
para4(_initialRaisedAmounts): 2000000
para5(_initialMinAmount): 100
para6(_initialMaxAmount): 500
para7(_initialFundsWallet): 0xcF93c8935F1c40b7851697b36AB92B6Be0aFd24F
para8(_uri): ""
para9(_data): 0x00

ERC1155Asteroid#create
para1(_initialOwner): 0xcF93c8935F1c40b7851697b36AB92B6Be0aFd24F
para2(_id): 102
para3(_initialSupply): 10000
para4(_initialRaisedAmounts): 5000000
para5(_initialMinAmount): 500
para6(_initialMaxAmount): 3000
para7(_initialFundsWallet): 0xcF93c8935F1c40b7851697b36AB92B6Be0aFd24F
para8(_uri): ""
para9(_data): 0x00


```
