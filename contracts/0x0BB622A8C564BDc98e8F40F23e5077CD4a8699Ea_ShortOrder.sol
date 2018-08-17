pragma solidity ^0.4.18;

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to,uint256 _value) returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from,address _to,uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender,uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner,address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from,address indexed _to,uint256 _value);
  event Approval(address indexed _owner,address indexed _spender,uint256 _value);

  uint decimals;
  string name;
}

contract SafeMath {
  function safeMul(uint a,uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }


  function safeDiv(uint a,uint b) internal returns (uint) {
    uint c = a / b;
    return c;
  }

  function safeSub(uint a,uint b) internal returns (uint) {
    assert(b &lt;= a);
    return a - b;
  }

  function safeAdd(uint a,uint b) internal returns (uint) {
    uint c = a + b;
    assert(c&gt;=a &amp;&amp; c&gt;=b);
    return c;
  }

}

contract ShortOrder is SafeMath {

  address admin;

  struct Order {
    uint coupon;
    uint balance;
    bool tokenDeposit;
    mapping (address =&gt; uint) shortBalance;
    mapping (address =&gt; uint) longBalance;
  }

  mapping (address =&gt; mapping (bytes32 =&gt; Order)) orderRecord;

  event TokenFulfillment(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint amount);
  event CouponDeposit(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint value);
  event LongPlace(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint value);
  event LongBought(address[2] sellerShort,uint[5] amountNonceExpiryDM,uint8 v,bytes32[3] hashRS,uint value);
  event TokenLongExercised(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint couponAmount,uint amount);
  event EthLongExercised(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint couponAmount,uint amount);
  event DonationClaimed(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint coupon,uint balance);
  event NonActivationWithdrawal(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint coupon);
  event ActivationWithdrawal(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs,uint balance);

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function ShortOrder() {
    admin = msg.sender;
  }

  function changeAdmin(address _admin) external onlyAdmin {
    admin = _admin;
  }

  function tokenFulfillmentDeposit(address[2] tokenUser,uint amount,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,orderHash),v,rs[0],rs[1]) == msg.sender &amp;&amp;
      block.number &gt; minMaxDMWCPNonce[2] &amp;&amp;
      block.number &lt;= minMaxDMWCPNonce[3] &amp;&amp; 
      orderRecord[tokenUser[1]][orderHash].balance &gt;= minMaxDMWCPNonce[0] &amp;&amp;
      amount == safeDiv(orderRecord[msg.sender][orderHash].balance,minMaxDMWCPNonce[6]) &amp;&amp;
      !orderRecord[msg.sender][orderHash].tokenDeposit
    );
    Token(tokenUser[0]).transferFrom(msg.sender,this,amount);
    orderRecord[msg.sender][orderHash].shortBalance[tokenUser[0]] = safeAdd(orderRecord[msg.sender][orderHash].shortBalance[tokenUser[0]],amount);
    orderRecord[msg.sender][orderHash].tokenDeposit = true;
    TokenFulfillment(tokenUser,minMaxDMWCPNonce,v,rs,amount);
  }
 
  function depositCoupon(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs) external payable {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,orderHash),v,rs[0],rs[1]) == msg.sender &amp;&amp;
      msg.value == minMaxDMWCPNonce[5] &amp;&amp;
      block.number &lt;= minMaxDMWCPNonce[2]
    );
    orderRecord[msg.sender][orderHash].coupon = safeAdd(orderRecord[msg.sender][orderHash].coupon,msg.value);
    CouponDeposit(tokenUser,minMaxDMWCPNonce,v,rs,msg.value);
  }

  function placeLong(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs) external payable {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,orderHash),v,rs[0],rs[1]) == tokenUser[1] &amp;&amp;
      block.number &lt;= minMaxDMWCPNonce[2] &amp;&amp;
      orderRecord[tokenUser[1]][orderHash].coupon == minMaxDMWCPNonce[5] &amp;&amp;
      orderRecord[tokenUser[1]][orderHash].balance &lt;= minMaxDMWCPNonce[1]
    );
    orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = safeAdd(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender],msg.value);
    orderRecord[tokenUser[1]][orderHash].balance = safeAdd(orderRecord[tokenUser[1]][orderHash].balance,msg.value);
    LongPlace(tokenUser,minMaxDMWCPNonce,v,rs,msg.value);
  }
  
  function buyLong(address[2] sellerShort,uint[5] amountNonceExpiryDM,uint8 v,bytes32[3] hashRS) external payable {
    bytes32 longTransferHash = keccak256 (
        sellerShort[0],
        amountNonceExpiryDM[0],
        amountNonceExpiryDM[1],
        amountNonceExpiryDM[2]
    );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,longTransferHash),v,hashRS[1],hashRS[2]) == sellerShort[1] &amp;&amp;
      block.number &gt; amountNonceExpiryDM[3] &amp;&amp;
      block.number &lt;= safeSub(amountNonceExpiryDM[4],amountNonceExpiryDM[2]) &amp;&amp;
      msg.value == amountNonceExpiryDM[0]
    );
    sellerShort[0].transfer(amountNonceExpiryDM[0]);
    orderRecord[sellerShort[1]][hashRS[0]].longBalance[msg.sender] = orderRecord[sellerShort[1]][hashRS[0]].longBalance[sellerShort[0]];
    orderRecord[sellerShort[1]][hashRS[0]].longBalance[sellerShort[0]] = uint(0);
    LongBought(sellerShort,amountNonceExpiryDM,v,hashRS,amountNonceExpiryDM[0]);
  }

  function exerciseLong(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,orderHash),v,rs[0],rs[1]) == tokenUser[1] &amp;&amp;
      block.number &gt; minMaxDMWCPNonce[3] &amp;&amp;
      block.number &lt;= minMaxDMWCPNonce[4] &amp;&amp;
      orderRecord[tokenUser[1]][orderHash].balance &gt;= minMaxDMWCPNonce[0]
    );
    uint couponProportion = safeDiv(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender],orderRecord[tokenUser[1]][orderHash].balance);
    uint couponAmount;
    if(orderRecord[msg.sender][orderHash].tokenDeposit) {
      couponAmount = safeMul(orderRecord[tokenUser[1]][orderHash].coupon,couponProportion);
      uint amount = safeDiv(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender],minMaxDMWCPNonce[6]);
      msg.sender.transfer(couponAmount);
      Token(tokenUser[0]).transfer(msg.sender,amount);
      orderRecord[tokenUser[1]][orderHash].coupon = safeSub(orderRecord[tokenUser[1]][orderHash].coupon,couponAmount);
      orderRecord[tokenUser[1]][orderHash].balance = safeSub(orderRecord[tokenUser[1]][orderHash].balance,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
      orderRecord[tokenUser[1]][orderHash].shortBalance[tokenUser[0]] = safeSub(orderRecord[tokenUser[1]][orderHash].shortBalance[tokenUser[0]],amount);
      orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = uint(0);
      TokenLongExercised(tokenUser,minMaxDMWCPNonce,v,rs,couponAmount,amount);
    }
    else if(!orderRecord[msg.sender][orderHash].tokenDeposit){
      couponAmount = safeMul(orderRecord[tokenUser[1]][orderHash].coupon,couponProportion);
      msg.sender.transfer(safeAdd(couponAmount,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]));
      orderRecord[tokenUser[1]][orderHash].coupon = safeSub(orderRecord[tokenUser[1]][orderHash].coupon,couponAmount);
      orderRecord[tokenUser[1]][orderHash].balance = safeSub(orderRecord[tokenUser[1]][orderHash].balance,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
      orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = uint(0); 
      EthLongExercised(tokenUser,minMaxDMWCPNonce,v,rs,couponAmount,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
    }
  }

  function claimDonations(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs) external onlyAdmin {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,orderHash),v,rs[0],rs[1]) == tokenUser[1] &amp;&amp;
      block.number &gt; minMaxDMWCPNonce[4]
    );
    admin.transfer(safeAdd(orderRecord[tokenUser[1]][orderHash].coupon,orderRecord[tokenUser[1]][orderHash].balance));
    Token(tokenUser[0]).transfer(admin,orderRecord[tokenUser[1]][orderHash].shortBalance[tokenUser[0]]);
    orderRecord[tokenUser[1]][orderHash].balance = uint(0);
    orderRecord[tokenUser[1]][orderHash].coupon = uint(0);
    orderRecord[tokenUser[1]][orderHash].shortBalance[tokenUser[0]] = uint(0);
    DonationClaimed(tokenUser,minMaxDMWCPNonce,v,rs,orderRecord[tokenUser[1]][orderHash].coupon,orderRecord[tokenUser[1]][orderHash].balance);
  }

  function nonActivationShortWithdrawal(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,orderHash),v,rs[0],rs[1]) == msg.sender &amp;&amp;
      block.number &gt; minMaxDMWCPNonce[2] &amp;&amp;
      orderRecord[tokenUser[1]][orderHash].balance &lt; minMaxDMWCPNonce[0]
    );
    msg.sender.transfer(orderRecord[msg.sender][orderHash].coupon);
    orderRecord[msg.sender][orderHash].coupon = uint(0);
    NonActivationWithdrawal(tokenUser,minMaxDMWCPNonce,v,rs,orderRecord[msg.sender][orderHash].coupon);
  }

  function nonActivationWithdrawal(address[2] tokenUser,uint[8] minMaxDMWCPNonce,uint8 v,bytes32[2] rs) external {
    bytes32 orderHash = keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
    require(
      ecrecover(keccak256(&quot;\x19Ethereum Signed Message:\n32&quot;,orderHash),v,rs[0],rs[1]) == tokenUser[1] &amp;&amp;
      block.number &gt; minMaxDMWCPNonce[2] &amp;&amp;
      block.number &lt;= minMaxDMWCPNonce[4] &amp;&amp;
      orderRecord[tokenUser[1]][orderHash].balance &lt; minMaxDMWCPNonce[0]
    );
    msg.sender.transfer(orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
    orderRecord[tokenUser[1]][orderHash].balance = safeSub(orderRecord[tokenUser[1]][orderHash].balance,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
    orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender] = uint(0);
    ActivationWithdrawal(tokenUser,minMaxDMWCPNonce,v,rs,orderRecord[tokenUser[1]][orderHash].longBalance[msg.sender]);
  }

  function returnBalance(address _creator,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[_creator][orderHash].balance;
  }

  function returnTokenBalance(address[2] creatorToken,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[creatorToken[0]][orderHash].shortBalance[creatorToken[1]];
  }

  function returnUserBalance(address[2] creatorUser,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[creatorUser[0]][orderHash].longBalance[creatorUser[1]];
  }

  function returnCoupon(address _creator,bytes32 orderHash) external constant returns (uint) {
    return orderRecord[_creator][orderHash].coupon;
  }

  function returnTokenDepositState(address _creator,bytes32 orderHash) external constant returns (bool) {
    return orderRecord[_creator][orderHash].tokenDeposit;
  }
 
  function returnHash(address[2] tokenUser,uint[8] minMaxDMWCPNonce)  external pure returns (bytes32) {
    return  
      keccak256 (
        tokenUser[0],
        tokenUser[1],
        minMaxDMWCPNonce[0],
        minMaxDMWCPNonce[1],
        minMaxDMWCPNonce[2], 
        minMaxDMWCPNonce[3],
        minMaxDMWCPNonce[4],
        minMaxDMWCPNonce[5],
        minMaxDMWCPNonce[6], 
        minMaxDMWCPNonce[7]
      );
  }


  function returnAddress(bytes32 orderHash,uint8 v,bytes32[2] rs) external pure returns (address) {
    return ecrecover(orderHash,v,rs[0],rs[1]);
  }

  function returnHashLong(address seller,uint[3] amountNonceExpiry)  external pure returns (bytes32) {
    return keccak256(seller,amountNonceExpiry[0],amountNonceExpiry[1],amountNonceExpiry[2]);
  }

  function returnLongAddress(bytes32 orderHash,uint8 v,bytes32[2] rs) external pure returns (address) {
    return ecrecover(orderHash,v,rs[0],rs[1]);
  }

  function returnAmount(address _creator,uint _price,bytes32 orderHash) external  view returns (uint) {
    return safeDiv(orderRecord[_creator][orderHash].balance,_price);
  }


}