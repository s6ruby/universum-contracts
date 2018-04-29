## adapted ruby version (for universum)
#
# original ethereum Vyper Port of MyToken
#  see https://github.com/ethereum/vyper/blob/master/examples/tokens/vypercoin.v.py
#
#
#  to test the contract script run:
#   $ ruby  tokens/token.rb


require_relative 'universum'


class Token < Contract


  # Events of the token.
  class Transfer < Event
    def initialize( from:, to:, value: )  ## _from: indexed(address), _to: indexed(address), _value: uint256
      @from  = from
      @to    = to
      @value = value
    end
  end
  class Approval < Event
    def initialize( owner:, spender:, value: )  ##  _owner: indexed(address), _spender: indexed(address), _value: uint256
      @owner   = owner
      @spender = spender
      @value   = value
    end
  end


=begin
# Variables of the token.
name:        public(bytes32)
symbol:      public(bytes32)
totalSupply: public(uint256)
decimals:    public(uint256)
balances:    int128[address]
allowed:     int128[address][address]
=end

  def initialize( name:, symbol:, decimals:, initial_supply: ) ## _name: bytes32, _symbol: bytes32, _decimals: uint256, _initialSupply: uint256
    @name     = name
    @symbol   = symbol
    @decimals = decimals
    @total_supply =  initial_supply * (10 ** decimals)   # uint256_mul(_initialSupply, uint256_exp(convert(10, 'uint256'), _decimals))
    @balances     = Hash.new(0)    ## note: special hash (default value is 0 and NOT nil)
    @balances[ msg.sender ] = @total_supply   ##FIX    ## self.balances[msg.sender] = convert(self.totalSupply, 'int128')
    @allowed =   {}
  end


  # What is the balance of a particular account?
  def balance_of( owner: )  ## (_owner: address) -> uint256:
    ##  todo/fix: return 0 for nil (n/a - not available) - why? why not?
    ##  note: will return 0 if not found (uses Hash.new(0) for 0 default)
    ##  todo/fix:  use Hash.new(0)  or just {} - why? why not???
    @balances[ owner ]   ##  return convert(self.balances[_owner], 'uint256')
  end


  # Send `_value` tokens to `_to` from your account
  ## fix/todo: always use value (NOT amount) - why? why not?
  def transfer( to:, amount: )  ## (_to: address, _amount: int128(uint256)) -> bool:
    if assert( @balances[msg.sender] >= amount ) &&
       assert( @balances[to] + amount >= @balances[to] )

      @balances[msg.sender] -= amount  # Subtract from the sender
      @balances[to]         += amount  # Add the same to the recipient

      log Transfer.new( from: msg.sender, to: to, value: amount )   # log transfer event.

      true
    else
      false
    end
  end

  # Transfer allowed tokens from a specific account to another.
  def transfer_from( from:, to:, value: ) ###(_from: address, _to: address, _value: int128(uint256)) -> bool:
    ## make sure allowed is not empty
    @allowed[from] ||= {}
    @allowed[from][msg.sender] ||= 0

    if assert( value <= @allowed[from][msg.sender] ) &&
       assert( value <= @balances[from] )

      @balances[from] -= value  # decrease balance of from address.
      @allowed[from][msg.sender] -= value  # decrease allowance.
      @balances[to]  += value  # incease balance of to address.

      log Transfer.new( from: from, to: to, value: value )   # log transfer event.

      true
    else
      false
    end
  end

  # Allow _spender to withdraw from your account, multiple times, up to the _value amount.
  # If this function is called again it overwrites the current allowance with _value.
  #
  # NOTE: We would like to prevent attack vectors like the one described here:
  #       https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.m9fhqynw2xvt
  #       and discussed here:
  #       https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  #
  #       Clients SHOULD make sure to create user interfaces in such a way that they
  #       set the allowance first to 0 before setting it to another value for the
  #       same spender. THOUGH The contract itself shouldn't enforce it, to allow
  #       backwards compatilibilty with contracts deployed before.

  def approve( spender:, amount: )   ##(_spender: address, _amount: int128(uint256)) -> bool:
    @allowed[msg.sender] ||= {}  ## make sure allowed is not empty
    @allowed[msg.sender][spender] = amount

    log Approval.new( owner: msg.sender, spender: spender, value: amount )

    true
  end


  # Get the allowance an address has to spend another's token.
  def allowance( owner:, spender: )  ## _owner: address, _spender: address
    ## make sure allowed is not empty
    @allowed[owner] ||= {}
    @allowed[owner][spender] ||= 0

    @allowed[owner][spender]
  end

end ## class Token



#############
#  start testing...


## sample event handler
class EventHandler
  def handle( event )
     puts "new event:"
     pp event
  end
end

Contract.handlers << EventHandler.new

## Contract.msg = Contract::Msg.new( sender: '0x0000' )
## pp Contract.msg


token = Token.new(
  name:          'Your Crypto Token',
  symbol:        'YOU',
  decimals:       8,
  initial_supply: 1_000_000
)

pp token


pp token.balance_of( owner: '0x0000' )
pp token.balance_of( owner: '0x0001' )

pp token.transfer( to: '0x0001', amount: 100 )
pp token.balance_of( owner: '0x0001' )

pp token.transfer( to: '0x0002', amount: 200 )
pp token.balance_of( owner: '0x0002' )

## note: NOT pre-approved (no allowance) - will FAIL
pp token.transfer_from( from: '0x0001', to: '0x0003', value: 30 )
pp token.allowance( owner: '0x0000', spender: '0x0001' )

pp token.approve( spender: '0x0001', amount: 50 )
pp token.allowance( owner: '0x0001', spender: '0x0000' )


### change sender to 0x0001
pp Contract.msg( sender: '0x0001' )
## Contract.msg = Contract::Msg.new( sender: '0x0001' )
## pp Contract.msg

pp token.transfer_from( from: '0x0000', to: '0x0003', value: 30 )
## pp token.transfer( to: '0x0000', amount: 1 )
pp token.balance_of( owner: '0x0003' )
pp token.balance_of( owner: '0x0000' )
pp token.balance_of( owner: '0x0001' )


### change sender back to 0x0000
pp Contract.msg( sender: '0x0000' )

pp token.transfer( to: '0x0001', amount: 1 )
pp token.balance_of( owner: '0x0000' )
pp token.balance_of( owner: '0x0001' )
