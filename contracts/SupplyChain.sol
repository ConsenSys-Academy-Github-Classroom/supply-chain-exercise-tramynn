// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner;
  // <skuCount>
  uint public skuCount;
  // <items mapping>
  mapping ( uint => Item ) public items;
  // <enum State: ForSale, Sold, Shipped, Received>
  enum State { ForSale, Sold, Shipped, Received }
  // <struct Item: name, sku, price, state, seller, and buyer>
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  /* 
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);
  // <LogSold event: sku arg>
  event LogSold(uint sku);
  // <LogShipped event: sku arg>
  event LogShipped(uint sku);
  // <LogReceived event: sku arg>
  event LogReceived(uint sku);

  /* 
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract
  modifier isOwner (address _owner) {
    require( msg.sender == _owner, "Owner must be the same as the message sender." );
    _;
  }
  // <modifier: isOwner

  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  modifier forSale (uint _sku) {
    require( 
      // item with the given sku has the state ForSale
      items[_sku].state == State.ForSale && items[_sku].seller != address(0)
      , "Item is not for sale or invalid seller address"
    );
    _;
  }
  modifier sold(uint _sku) {
    require( items[_sku].state == State.Sold, "Item is sold" );
    _;
  }
  modifier shipped(uint _sku) {
    require( items[_sku].state == State.Shipped, "Item is shipped" );
    _;
  }
  modifier received(uint _sku) {
    require( items[_sku].state == State.Received, "Item is received" );
    _;
  }

  constructor() public {
    // 1. Set the owner to the transaction sender
    owner = msg.sender;
    // 2. Initialize the sku count to 0. Question, is this necessary?
    // Not necessary because uint default is 0
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    // hint:
    items[skuCount] = Item( {
      name: _name, 
      sku: skuCount, 
      price: _price, 
      state: State.ForSale, 
      seller: msg.sender, 
      buyer: address(0)
    });
    // 2. Increment the skuCount by one
    skuCount = skuCount + 1;
    // 3. Emit the appropriate event
    emit LogForSale(skuCount);
    // 4. return true
    return true;
  }

  // Implement this buyItem function. 
  function buyItem(uint _sku)
    // 1. it should be payable in order to receive refunds
    public 
    payable
    //    - if the item is for sale, 
    forSale(_sku)
    //    - if the buyer paid enough, 
    paidEnough(items[_sku].price)
    //    - check the value after the function is called to make 
    //      sure the buyer is refunded any excess ether sent. 
    checkValue(_sku)
  {
    // 2. this should transfer money to the seller,
    items[_sku].seller.transfer(items[_sku].price);
    // 3. set the buyer as the person who called this transaction, 
    items[_sku].buyer = msg.sender;
    // 4. set the state to Sold. 
    items[_sku].state = State.Sold;
    // 6. call the event associated with this function!
    emit LogSold( _sku );
  }

  function shipItem(uint _sku) 
  // 1. Add modifiers to check:
    public
  //    - the item is sold already 
    sold(_sku)
  //    - the person calling this function is the seller. 
    verifyCaller(items[_sku].seller)
  {
  // 2. Change the state of the item to shipped. 
    items[_sku].state = State.Shipped;
  // 3. call the event associated with this function!
    emit LogShipped(_sku);
  }

  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint _sku) 
    public
    //    - the item is shipped already 
    shipped(_sku)
    //    - the person calling this function is the buyer.
    verifyCaller(items[_sku].buyer)
  {
    // 2. Change the state of the item to received. 
    items[_sku].state = State.Received;
    // 3. Call the event associated with this function!
    emit LogReceived(_sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
    {
      name = items[_sku].name;
      sku = items[_sku].sku;
      price = items[_sku].price;
      state = uint(items[_sku].state);
      seller = items[_sku].seller;
      buyer = items[_sku].buyer;
      return (name, sku, price, state, seller, buyer);
  }
}
