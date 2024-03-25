# @version 0.3.7
"""
@title Swap Stable Burner
@notice Swaps an asset into another asset using a Stable pool, and forwards to another burner
"""

from vyper.interfaces import ERC20

interface StableSwap:
    def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256): payable
    def coins(_i: uint256) -> address: view


struct SwapData:
    pool: address
    coin: address
    receiver: address
    i: int128
    j: int128


ETH_ADDRESS: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE

is_approved: HashMap[address, HashMap[address, bool]]
swap_data: public(HashMap[address, SwapData])
recovery: public(address)
is_killed: public(bool)

owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


@external
def __init__(_recovery: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @dev Unlike other burners, this contract may transfer tokens to
         multiple addresses after the swap. Receiver addresses are
         set by calling `set_swap_data` instead of setting it
         within the constructor.
    @param _recovery Address that tokens are transferred to during an
                     emergency token recovery.
    @param _owner Owner address. Can kill the contract, recover tokens
                  and modify the recovery address.
    @param _emergency_owner Emergency owner address. Can kill the contract
                            and recover tokens.
    """
    self.recovery = _recovery
    self.owner = _owner
    self.emergency_owner = _emergency_owner


@payable
@external
def __default__():
    # required to receive ether during intermediate swaps
    pass


@payable
@external
def burn(_coin: address) -> bool:
    """
    @notice Convert `_coin` by swapping and transfer to another burner
    @param _coin Address of the coin being converted
    @return bool success
    """
    assert not self.is_killed  # dev: is killed

    amount: uint256 = 0
    eth_amount: uint256 = 0

    if _coin == ETH_ADDRESS:
        amount = self.balance
        eth_amount = self.balance
    else:
        # transfer coins from caller
        amount = ERC20(_coin).balanceOf(msg.sender)
        if amount != 0:
            response: Bytes[32] = raw_call(
                _coin,
                _abi_encode(
                    msg.sender,
                    self,
                    amount,
                    method_id=method_id("transferFrom(address,address,uint256)")
                ),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)

        # get actual balance in case of transfer fee or pre-existing balance
        amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        swap_data: SwapData = self.swap_data[_coin]
        StableSwap(swap_data.pool).exchange(swap_data.i, swap_data.j, amount, 0, value=eth_amount)

        if swap_data.receiver != empty(address):
            if swap_data.coin == ETH_ADDRESS:
                raw_call(swap_data.receiver, b"", value=self.balance)
            else:
                amount = ERC20(swap_data.coin).balanceOf(self)
                response: Bytes[32] = raw_call(
                    swap_data.coin,
                    _abi_encode(swap_data.receiver, amount, method_id=method_id("transfer(address,uint256)")),
                    max_outsize=32,
                )
                if len(response) != 0:
                    assert convert(response, bool)

    return True


@internal
def _set_swap_data(_from: address, _swap_data: SwapData):
    assert StableSwap(_swap_data.pool).coins(convert(_swap_data.i, uint256)) == _from
    assert StableSwap(_swap_data.pool).coins(convert(_swap_data.j, uint256)) == _swap_data.coin

    self.swap_data[_from] = _swap_data

    if _from != ETH_ADDRESS:
        response: Bytes[32] = raw_call(
            _from,
            _abi_encode(_swap_data.pool, max_value(uint256), method_id=method_id("approve(address,uint256)")),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)


@external
def set_swap_data(
    _from: address,
    _pool: address,
    _to: address,
    _receiver: address,
    _i: int128,
    _j: int128,
) -> bool:
    """
    @notice Set conversion and transfer data for `_from`
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner

    self._set_swap_data(_from, SwapData({
        pool: _pool,
        coin: _to,
        receiver: _receiver,
        i: _i,
        j: _j,
    }))

    return True



@external
def set_many_swap_data(_from: DynArray[address, 20], _swap_datas: DynArray[SwapData, 20]):
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    assert len(_swap_datas) == len(_from), "Incorrect input"

    i: uint256 = 0
    for data in _swap_datas:
        self._set_swap_data(_from[i], data)
        i += 1



@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens or Ether from this contract
    @dev Tokens are sent to the recovery address
    @param _coin Token address
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner

    if _coin == ETH_ADDRESS:
        raw_call(self.recovery, b"", value=self.balance)
    else:
        amount: uint256 = ERC20(_coin).balanceOf(self)
        response: Bytes[32] = raw_call(
            _coin,
            _abi_encode(self.recovery, amount, method_id=method_id("transfer(address,uint256)")),
            max_outsize=32,
        )
        if len(response) != 0:
            assert convert(response, bool)

    return True


@external
def set_recovery(_recovery: address) -> bool:
    """
    @notice Set the token recovery address
    @param _recovery Token recovery address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.recovery = _recovery

    return True


@external
def set_killed(_is_killed: bool) -> bool:
    """
    @notice Set killed status for this contract
    @dev When killed, the `burn` function cannot be called
    @param _is_killed Killed status
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.is_killed = _is_killed

    return True



@external
def commit_transfer_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.future_owner = _future_owner

    return True


@external
def accept_transfer_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_owner  # dev: only owner
    self.owner = msg.sender

    return True


@external
def commit_transfer_emergency_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.emergency_owner  # dev: only owner
    self.future_emergency_owner = _future_owner

    return True


@external
def accept_transfer_emergency_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_emergency_owner  # dev: only owner
    self.emergency_owner = msg.sender

    return True