// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ZombieFactory {
    struct Zombie {
        string name;
        uint256 dna;
        uint256 createdAt;
    }

    uint256 public constant DNA_MODULUS = 10 ** 16;

    Zombie[] private zombies;
    mapping(uint256 => address) public zombieToOwner;
    mapping(address => uint256) public ownerZombieCount;

    event ZombieCreated(uint256 indexed id, address indexed owner, string name, uint256 dna);

    function createZombie(string calldata name) external returns (uint256 id) {
        require(bytes(name).length > 0, "Empty name");
        require(ownerZombieCount[msg.sender] == 0, "Already has zombie");

        uint256 dna = uint256(keccak256(abi.encodePacked(msg.sender, name))) % DNA_MODULUS;

        zombies.push(Zombie(name, dna, block.timestamp));
        id = zombies.length - 1;

        zombieToOwner[id] = msg.sender;
        ownerZombieCount[msg.sender] += 1;

        emit ZombieCreated(id, msg.sender, name, dna);
    }

    function totalZombies() external view returns (uint256) {
        return zombies.length;
    }

    function getZombie(uint256 id) external view returns (string memory, uint256, uint256) {
        Zombie storage z = zombies[id];
        return (z.name, z.dna, z.createdAt);
    }
}
