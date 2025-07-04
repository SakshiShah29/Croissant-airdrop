//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Croisaant is ERC20, Ownable {
    constructor() ERC20("Croissant", "CROISSANT") Ownable(msg.sender) {
        //The initial supply willl be handled  by owner minting tokens as needed rather than
        //a fixed supply at deployment.
        //This allows for flexibility in token distribution.
    }
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}
