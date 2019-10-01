/// hmac(key, message) = sha1[ (actual_key ^ outer_padding) |+| sha1((actual_key ^ inner_padding) |+| message) ]
/// actual_key = (length of key > block size)? sha1(key) : key
/// 
/// @param key{string}       The key to use in the HMAC algorithm
/// @param message{string}   The message to compute the checksum for.
/// 
/// Returns: The HMAC-SHA1 hash of the message, as a string of 40 hexadecimal digits

var _key        = argument0;
var _message    = argument1;
var _block_size = 64; //SHA1 has a block size of 64 bytes
var _hash_size  = 20; //SHA1 returns a hash that's 20 bytes long
                      //NB. The functions return a string that

//For the inner padding, we're concatenating a SHA1 block to the message
var _inner_size = _block_size + string_byte_length(_message);
//Whereas for the outer padding, we're concatenating a SHA1 block to a hash (of the inner padding)
var _outer_size = _block_size + _hash_size;

//Create buffers so we can handle raw binary data more easily
var _key_buffer   = buffer_create(_block_size, buffer_fixed, 1);
var _inner_buffer = buffer_create(_inner_size, buffer_fixed, 1);
var _outer_buffer = buffer_create(_outer_size, buffer_fixed, 1);

//If the key is longer than the block size then we need to make a new key
//The new key is just the SHA1 hash of the original key!
if (string_byte_length(_key) > _block_size)
{
    var _sha1_key = sha1_string_utf8(_key);
    //GameMaker's SHA1 functions return a hex string so we need to turn that into individual bytes
    for(var _i = 0; _i < _hash_size; ++_i) buffer_write(_key_buffer, buffer_u8, hex_string_byte(_sha1_key, _i));
}
else
{
    //buffer_string writes a 0-byte to the buffer at the end of the string. We don't want this!
    //Fortunately GameMaker has buffer_text which doesn't write the unwanted 0-byte
    buffer_write(_key_buffer, buffer_text, _key);
}

//Bitwise XOR between the inner/outer padding and the key
for(var _i = 0; _i < _block_size; ++_i)
{
    var _key_byte = buffer_peek(_key_buffer, _i, buffer_u8);
    //Couple magic numbers here; these are specified in the HMAC standard and should not be changed
    buffer_poke(_inner_buffer, _i, buffer_u8, $36 ^ _key_byte);
    buffer_poke(_outer_buffer, _i, buffer_u8, $5C ^ _key_byte);
}

//Append the message to the inner buffer
//We start at block size bytes
buffer_seek(_inner_buffer, buffer_seek_start, _block_size);
buffer_write(_inner_buffer, buffer_text, _message);

//Now hash the inner buffer
var _sha1_inner = buffer_sha1(_inner_buffer, 0, _inner_size);

//Append the hash of the inner buffer to the outer buffer
//GameMaker's SHA1 functions return a hex string so we need to turn that into individual bytes
buffer_seek(_outer_buffer, buffer_seek_start, _block_size);
for(var _i = 0; _i < _hash_size; ++_i) buffer_write(_outer_buffer, buffer_u8, hex_string_byte(_sha1_inner, _i));

//Finally we get the hash of the outer buffer too
var _result = buffer_sha1(_outer_buffer, 0, _outer_size);

//Clean up all the buffers we created so we don't get any memory leaks
buffer_delete(_key_buffer  );
buffer_delete(_inner_buffer);
buffer_delete(_outer_buffer);

//And return the result!
return _result;