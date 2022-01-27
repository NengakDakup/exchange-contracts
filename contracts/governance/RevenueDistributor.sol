// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RevenueDistributor {
    using SafeERC20 for IERC20;

    struct Recipient {
        address account;
        uint allocation;
    }

    mapping(uint => Recipient) private _recipients;

    address public admin;
    uint private _recipientsLength;
    uint private constant DENOMINATOR = 10000;

    constructor(
        address newAdmin,
        Recipient[] memory newRecipients
    ) {
        admin = newAdmin;
        setRecipients(newRecipients);
    }

    function getRecipients() external view returns (Recipient[] memory) {
        require(_recipientsLength != 0, "no recipient exists");
        Recipient[] memory recipients =
            new Recipient[](_recipientsLength);
        for (uint i; i < _recipientsLength; ++i) {
            recipients[i] = _recipients[i];
        }
        return recipients;
    }

    function distributeToken(address token) external {
        uint amount = IERC20(token).balanceOf(address(this));
        require(amount != 0, "cannot distribute zero");
        // distribute to all but last recipient
        for (uint i; i < _recipientsLength - 1; ++i) {
            IERC20(token).safeTransfer(
                _recipients[i].account,
                amount * _recipients[i].allocation / DENOMINATOR
            );
        }
        // distribute the remaining to the last recipient
        IERC20(token).safeTransfer(
            _recipients[_recipientsLength - 1].account,
            IERC20(token).balanceOf(address(this))
        );
        emit TokenDistributed(token, amount);
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "sender is not admin");
        require(newAdmin != address(0), "invalid new admin");
        admin = newAdmin;
        emit AdminChanged(admin);
    }

    function setRecipients(Recipient[] memory newRecipients) public {
        if (_recipientsLength != 0) {
            require(msg.sender == admin, "sender is not admin");
        }
        _recipientsLength = newRecipients.length;
        require(
            _recipientsLength != 0 && _recipientsLength < 21,
            "invalid recipient number"
        );
        uint allocations;
        for (uint i; i < _recipientsLength; ++i) {
            Recipient memory recipient = newRecipients[i];
            require(
                recipient.account != address(0),
                "invalid recipient address"
            );
            require(recipient.allocation != 0, "invalid recipient allocation");
            _recipients[i] = recipient;
            allocations += recipient.allocation;
        }
        require(
            allocations == DENOMINATOR,
            "total allocations do not equal to denominator"
        );
        emit RecipientsChanged(newRecipients);
    }

    event TokenDistributed(address token, uint amount);
    event RecipientsChanged(Recipient[] newRecipients);
    event AdminChanged(address newAdmin);
}
