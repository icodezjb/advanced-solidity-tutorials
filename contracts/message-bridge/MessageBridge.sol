// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IMessengerFee} from "../bool/interfaces/IMessengerFee.sol";
import {IAnchor} from "../bool/interfaces/IAnchor.sol";
import {BoolConsumerBase} from "../bool/BoolConsumerBase.sol";


contract MessageBridge is BoolConsumerBase {
    event SentMsg(bytes32 id, bytes msg);
    event ReceiveMsg(bytes32 id, bytes msg);
    event SoTransferFailed(string revertReason);


    constructor(address _anchor) BoolConsumerBase(_anchor) {}

    // Calculate the cross-chain fee to be prepaid
    function calculateFee(
        uint32 dstChainId,
        uint32 len
    ) public view returns (uint256 fee) {
        address srcAnchor = _anchor;

        fee = IMessengerFee(IAnchor(srcAnchor).messenger()).cptTotalFee(
            srcAnchor,
            dstChainId,
            len,
            PURE_MESSAGE,
            bytes("")
        );
    }

    function send_msg(
        uint32 dstChainId,
        bytes memory payload
    ) external payable  {
        uint256 fee = calculateFee(dstChainId, uint32(payload.length));
//        require(msg.value >= fee, "MessageBridge: INSUFFICIENT_FEE");

        bytes32 id = _sendAnchor(
            fee,
            payable(msg.sender),
            PURE_MESSAGE,
            "",
            dstChainId,
            payload
        );

        if (id != bytes32(0)) {
            emit SentMsg(id, payload);
        }
    }

    function receiveFromAnchor(
        bytes32 txUniqueIdentification,
        bytes memory payload
    ) external override {
        emit ReceiveMsg(txUniqueIdentification, payload);
    }

    function _sendAnchor(
        uint256 callValue,
        address payable refundAddress,
        bytes32 crossType,
        bytes memory extraFeed,
        uint32 dstChainId,
        bytes memory payload
    ) internal override  returns (bytes32 txUniqueIdentification) {
        try IAnchor(_anchor).sendToMessenger{value: callValue}(
            refundAddress,
            crossType,
            extraFeed,
            dstChainId,
            payload
        ) returns(bytes32 id) {
            txUniqueIdentification = id;
        } catch (bytes memory returnData) {
            emit SoTransferFailed(getRevertMsg(returnData));
            txUniqueIdentification = bytes32(0);
        }
    }

    function getRevertMsg(bytes memory _returnData) public pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
        // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}