// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
/**
 * @title Condition of pay-to-mint, pay-to-transfer, burn-and-refund operation with cash
 * @author DARC Team
 * @notice All the condition expression functions related to Operator
 */


import "../MachineState.sol";
import "../MachineStateManager.sol";
import "../Utilities/StringUtils.sol";
import "../Utilities/OpcodeMap.sol";
import "../Plugin.sol";

contract Condition_TokenAndCash is MachineStateManager { 
  /**
   * The function to check the batch operation related condition expression
   * @param bIsBeforeOperation The flag to indicate if the plugin is before operation plugin
   * @param op The operation to be checked
   * @param param The parameter list of the condition expression
   * @param id The id of the condition expression
   */
  function tokenAndCashExpressionCheck(bool bIsBeforeOperation, Operation memory op, NodeParam memory param, uint256 id) internal view returns (bool) {
    if (id== 461)  return ID_461_TOKEN_X_OP_ANY_PRICE_GREATER_THAN(bIsBeforeOperation, op, param);
    if (id== 462)  return ID_462_TOKEN_X_OP_ANY_PRICE_LESS_THAN(bIsBeforeOperation, op, param);
    if (id== 463)  return ID_463_TOKEN_X_OP_ANY_PRICE_IN_RANGE(bIsBeforeOperation, op, param);
    if (id== 464)  return ID_464_TOKEN_X_OP_ANY_PRICE_EQUALS(bIsBeforeOperation, op, param);
    return false;
  }

  function ID_461_TOKEN_X_OP_ANY_PRICE_GREATER_THAN(bool bIsBeforeOperation, Operation memory op, NodeParam memory param) internal view returns (bool) {
    require(param.UINT256_2DARRAY.length == 1, "CE ID_461: The UINT256_2DARRAY length is not 1");
    require(param.UINT256_2DARRAY[0].length == 2, "CE ID_461: The UINT256_2DARRAY[0] length is not 1");
    if (bIsTokenOperationWithCash(op) == false) return false;
    (uint256[] memory tokenClassList, , uint256[] memory priceList) = getTokenClassAmountPriceList(op);
    require(tokenClassList.length == priceList.length, "CE ID_461: The token class list length is not equal to price list length");
    for (uint256 i = 0; i < tokenClassList.length; i++) {
      if (tokenClassList[i] == param.UINT256_2DARRAY[0][0] && priceList[i] > param.UINT256_2DARRAY[0][1]) { return true; }
    }
    return false;
  }

  function ID_462_TOKEN_X_OP_ANY_PRICE_LESS_THAN(bool bIsBeforeOperation, Operation memory op, NodeParam memory param) internal view returns (bool) {
    require(param.UINT256_2DARRAY.length == 1, "CE ID_462: The UINT256_2DARRAY length is not 1");
    require(param.UINT256_2DARRAY[0].length == 2, "CE ID_462: The UINT256_2DARRAY[0] length is not 1");
    if (bIsTokenOperationWithCash(op) == false) return false;
    (uint256[] memory tokenClassList, , uint256[] memory priceList) = getTokenClassAmountPriceList(op);
    require(tokenClassList.length == priceList.length, "CE ID_462: The token class list length is not equal to price list length");
    for (uint256 i = 0; i < tokenClassList.length; i++) {
      if (tokenClassList[i] == param.UINT256_2DARRAY[0][0] && priceList[i] < param.UINT256_2DARRAY[0][1]) { return true; }
    }
    return false;
  }

  function ID_463_TOKEN_X_OP_ANY_PRICE_IN_RANGE(bool bIsBeforeOperation, Operation memory op, NodeParam memory param) internal view returns (bool) {
    require(param.UINT256_2DARRAY.length == 1, "CE ID_463: The UINT256_2DARRAY length is not 1");
    require(param.UINT256_2DARRAY[0].length == 3, "CE ID_463: The UINT256_2DARRAY[0] length is not 1");
    if (bIsTokenOperationWithCash(op) == false) return false;
    (uint256[] memory tokenClassList, , uint256[] memory priceList) = getTokenClassAmountPriceList(op);
    require(tokenClassList.length == priceList.length, "CE ID_463: The token class list length is not equal to price list length");
    for (uint256 i = 0; i < tokenClassList.length; i++) {
      if (tokenClassList[i] == param.UINT256_2DARRAY[0][0] && priceList[i] >= param.UINT256_2DARRAY[0][1] && priceList[i] <= param.UINT256_2DARRAY[0][2]) { return true; }
    }
    return false;
  }

  function ID_464_TOKEN_X_OP_ANY_PRICE_EQUALS(bool bIsBeforeOperation, Operation memory op, NodeParam memory param) internal view returns (bool) {
    require(param.UINT256_2DARRAY.length == 1, "CE ID_464: The UINT256_2DARRAY length is not 1");
    require(param.UINT256_2DARRAY[0].length == 2, "CE ID_464: The UINT256_2DARRAY[0] length is not 1");
    if (bIsTokenOperationWithCash(op) == false) return false;
    (uint256[] memory tokenClassList, , uint256[] memory priceList) = getTokenClassAmountPriceList(op);
    require(tokenClassList.length == priceList.length, "CE ID_464: The token class list length is not equal to price list length");
    for (uint256 i = 0; i < tokenClassList.length; i++) {
      if (tokenClassList[i] == param.UINT256_2DARRAY[0][0] && priceList[i] == param.UINT256_2DARRAY[0][1]) { return true; }
    }
    return false;
  }

  

  // -------------------------------- below are helper functions ----------------------------
  function bIsTokenOperationWithCash(Operation memory op) internal pure returns (bool) {
    if (op.opcode == EnumOpcode.BATCH_PAY_TO_MINT_TOKENS 
    || op.opcode == EnumOpcode.BATCH_PAY_TO_TRANSFER_TOKENS
    || op.opcode == EnumOpcode.BATCH_BURN_TOKENS_AND_REFUND
    ) { return true; }
    return false;
  }

  function getTokenClassAmountPriceList(Operation memory op) internal pure returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    require(bIsTokenOperationWithCash(op), "CE ID_461: The operation is not token operation with cash(pay-to-mint, pay-to-transfer, burn-and-refund)");
    if (op.opcode == EnumOpcode.BATCH_PAY_TO_MINT_TOKENS) {
      return (op.param.UINT256_2DARRAY[0], op.param.UINT256_2DARRAY[1], op.param.UINT256_2DARRAY[2]);
    }
    if (op.opcode == EnumOpcode.BATCH_PAY_TO_TRANSFER_TOKENS) {
      return (op.param.UINT256_2DARRAY[0], op.param.UINT256_2DARRAY[2], op.param.UINT256_2DARRAY[3]);
    }
    if (op.opcode == EnumOpcode.BATCH_BURN_TOKENS_AND_REFUND) {
      return (op.param.UINT256_2DARRAY[0], op.param.UINT256_2DARRAY[1], op.param.UINT256_2DARRAY[2]);
    }
    return (new uint256[](0), new uint256[](0), new uint256[](0));
  }

}