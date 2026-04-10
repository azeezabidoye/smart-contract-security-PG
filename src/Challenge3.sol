// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract ChallengeTwo {
    mapping(address => bool) private hasSolved1;
    mapping(address => uint) userPoint;
    address[] public champions;
    mapping(address => string) public Names;

    function passKey(uint8 _key) external {
        require(
            keccak256(abi.encode(_key)) ==
                0x98a476f1687bc3d60a2da2adbcba2c46958e61fa2fb4042cd7bc5816a710195b,
            "invalid key"
        );
        hasSolved1[tx.origin] = true;
    }

    function getENoughPoint(string memory _name) external {
        require(hasSolved1[tx.origin], "go back and complete level 1");
        userPoint[tx.origin]++;
        msg.sender.call("");
        if (userPoint[tx.origin] == 4) {
            Names[tx.origin] = _name;
        } else {
            Names[tx.origin] = "";
        }
    }

    function addYourName() external {
        require(
            keccak256(abi.encode(Names[tx.origin])) !=
                keccak256(abi.encode("")),
            "invalid point Accumulated"
        );
        champions.push(tx.origin);
    }

    function getAllwiners() external view returns (string[] memory _names) {
        _names = new string[](champions.length);
        for (uint i; i < champions.length; i++) {
            _names[i] = Names[champions[i]];
        }
    }
}
