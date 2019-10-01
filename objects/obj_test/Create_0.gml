//Set our HMAC key. You can make this whatever you want
global.hmac_key = "The quick brown fox jumped over the lazy dog!";

//Create some save data
save_map = ds_map_create();
ds_map_add(save_map, "Hello", "World");

//Choose where to save the file
filename = "protected.dat";



#region Save

//Find our savefile string
var _save_string = json_encode(save_map);

//Make an HMAC hash
//SHA1 strings are exactly 40 characters long
var _hash = sha1_string_utf8_hmac(global.hmac_key, _save_string);

//Append the HMAC hash onto the string
_save_string += "#" + _hash + "#";

//Now save the string to a file
var _file = file_text_open_write(filename);
file_text_write_string(_file, _save_string);
file_text_close(_file);

#endregion



#region Load

//Load in the save string
var _file = file_text_open_read(filename);
var _save_string = file_text_read_string(_file);
file_text_close(_file);

//Find the hash tacked onto the end of the save string
var _expected_hash = string_copy(_save_string, string_length(_save_string)-40, 40);

//Trim off the hash
//The hash is always exactly 42 characters - 2 for the two hash symbols and 40 for the SHA1 string
var _hashless_string = string_copy(_save_string, 1, string_length(_save_string)-42);

//Make a hash from the new hashless string
//NB. We have to use the same hashing function as when we were saving
var _new_hash = sha1_string_utf8_hmac(global.hmac_key, _hashless_string);

//Check if the two hashes match
if (_expected_hash == _new_hash)
{
    //Savefile is valid! Let's load the savedata
    load_map = json_decode(_hashless_string);
}
else
{
    show_error("Savefile integrity check failed :(\n ", false);
}

#endregion