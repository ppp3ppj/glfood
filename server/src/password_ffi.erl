-module(password_ffi).
-export([hash/1, verify/2]).

%% Hash a plaintext password.
%% Returns <<"SALTHEX$HASHHEX">> stored in the DB.
hash(Password) ->
    Salt = crypto:strong_rand_bytes(16),
    SaltHex = binary:encode_hex(Salt),
    Hash = crypto:hash(sha256, <<Password/binary, Salt/binary>>),
    HashHex = binary:encode_hex(Hash),
    <<SaltHex/binary, "$", HashHex/binary>>.

%% Verify a plaintext password against a stored hash string.
verify(Password, Stored) ->
    case binary:split(Stored, <<"$">>) of
        [SaltHex, HashHex] ->
            Salt = hex_to_bin(SaltHex),
            Hash = crypto:hash(sha256, <<Password/binary, Salt/binary>>),
            ExpectedHex = binary:encode_hex(Hash),
            string:equal(ExpectedHex, HashHex, true);
        _ ->
            false
    end.

hex_to_bin(Hex) ->
    Upper = string:uppercase(Hex),
    << <<(erlang:binary_to_integer(<<H, L>>, 16))>> || <<H, L>> <= Upper >>.
