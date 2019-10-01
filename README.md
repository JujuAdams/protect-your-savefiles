<h1 align="center">Protect Your Savefiles</h1>

### @jujuadams

I started my gamedev career at the tender age of 5 by editing savefiles on an old Acorn computer. I think I was giving myself extra lives on James Pond. Unfortunately, that computer bit the dust when my house's ceiling collapsed directly onto it. I learnt a couple things from the experience:

1) Don't let your sink overflow because wet 18th Century ceilings are unstable and liable to collapse;
2) Savefiles can be a security weakness for games.

This short article will show you a way to solve one of these problems.

&nbsp;

Let's talk about "hashing algorithms". Hashing can refer to many things, but here we mean particular type of cryptographic function. A good hashing function has many properties, but let's focus on the important ones:

1) A hashing function takes a single input and gives a single output (of a fixed size);
2) If you run the hashing function twice on two slightly different inputs, the outputs should be different;
3) It's very hard to reverse the process - you shouldn't know the input given only the output;
4) It should be hard to find two different inputs that give the same output.

We call the output of hashing algorithm a "hash" or a "digest". There are lots of hashing functions out there, but we're going to use SHA1. We're not so concerned with the actual algorithm, just that it obeys the rules above. We're going to use a hash as a way to check that a savefile has not been edited - if the savefile changes, the hash of the savefile also changes.

&nbsp;

Let's say we have a savefile that we've made using a string returned by `json_encode()`. For those who aren't using JSON, you can use a string returned by `ini_open()` instead. Either way, we're going to be hashing a single string that represents all the data we want to save.

*(If you're really fancy you'll be using buffers - you'll still be able to protect your savefiles using a hash but your implementation will be a bit different. GM has some extra functions for hashing buffers so you'll need to use those.)*

What we're going to do is take a string that holds all of our savedata, make a hash for it, and add that hash onto the end of the string. Then when we load in the string we can separate it into two parts: our original input string, and our expected hash of that input string. We recompute the hash for the input string and if it's not what we're expected then someone has tampered with the savefile!

This is surprisingly easy to do in GameMaker, only a few lines of code. Here's how we save our file:

```
    //Find our savefile string
    var _save_string = json_encode(save_map);
    
    //Make a hash (we're using the UTF-8 hash variant here)
    //SHA1 hash strings are exactly 40 characters long
    var _hash = sha1_string_utf8(_save_string);
    
    //Append the hash onto the string
    _save_string += "#" + _hash + "#";
    
    //Now save the string to a file
    var _file = file_text_open_write(filename);
    file_text_write_string(_file, _save_string);
    file_text_close(_file);
```

Fun fact - the # symbol is never called "pound" in the UK, it's always been the "hash symbol", long before Twitter. Anyway, here's how we load our savefile and verify it:

```
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
    var _new_hash = sha1_string_utf8(_hashless_string);
    
    //Check if the two hashes match
    if (_expected_hash == _new_hash)
    {
        //Savefile is valid! Let's load the savedata
        load_map = json_decode(_hashless_string);
    }
    else
    {
        show_error("Savefile integrity check failed :(", false);
    }
```

Job done, that was easy. Savefiles protected, fame and fortune await, yeah? No... unfortunately, this hashing process isn't quite perfect. This system is sufficient to deter casual savefile editing but anyone a bit more determined will immediately be able to fool this system. Once a would-be hacker figures out the hashing algorithm then it's very easy to simply edit the savefile, recalculate the hash, and change the  hash stored in the savefile. Takes about 5 minutes. When the game loads in this edited savefile it doesn't know that anything's changed because the hash has changed too!

&nbsp;

Now, obviously I wouldn't have relived the traumatic memory of my first computer getting totalled by wet Georgian-era horse poop and straw if there wasn't a satisfying conclusion to all this.

Some very clever people (specifically Bellare/Canetti/Krawczyk in 1996\*) came up with a way to stop people from simply re-hashing an edited message. They called this algorithm "HMAC" - Hash-based Message Authentication Code. I like to think of it like this: HMAC encrypts the hash but not the rest of the message.

If we encrypt the hash then it solves the flaw we identified. If someone changes the savefile then tries to recalculate the hash to fool the game they'll get a different hash to what the game is expecting. Only the game can create HMAC hashes that are authentic which is exactly what we want.

&nbsp;

So, how do we use HMAC? The HMAC algorithm itself is relatively simple. Here it is as a compact definition:

`HMAC-SHA1(Key, Message)  =  SHA1((Key' ^ OuterPadding) |+| SHA1((Key' ^ InnerPadding) |+| Message))`

`|+|` means concatenation (i.e. sticking one thing onto the end of another) and `^` means a bitwise XOR operation.

We don't need to know exactly what this means to use it, fortunately! Let's focus in on the important details of this algorithm: The HMAC function takes two inputs - a "key" and the message we want to protect, and it returns a hash made using the SHA1 algorithm, just like before.

This means that we can drop this HMAC system into the savefile code we wrote up above with only a couple changes. This is extremely convenient. All we need to do is replace our hashing function with an HMAC variant, and then provide a key for the HMAC function. In our case, a key can be a string of any length. The key should never ever change - the key has to be the same so that we can verify savefiles in the future.

&nbsp;

Here's what this code looks like when we're using HMAC. First up, saving:

```
    //Find our savefile string
    var _save_string = json_encode(save_map);
    
    //Make an HMAC hash
    var _hmac_hash = sha1_string_utf8_hmac(global.hmac_key, _save_string);
    
    //Same as before - append the HMAC hash to the string
    _save_string += "#" + _hmac_hash + "#";
    var _file = file_text_open_write(filename);
    file_text_write_string(_file, _save_string);
    file_text_close(_file);
```

Did you know that hash browns are based on a Swiss dish called a "rösti"? Anyway, here's loading using HMAC:

```
    //Load in the save string
    var _file = file_text_open_read(filename);
    var _save_string = file_text_read_string(_file);
    file_text_close(_file);
    
    //Find the hash, as before
    var _expected_hash = string_copy(_save_string, string_length(_save_string)-40, 40);
    
    //Trim off the hash
    //Our HMAC hash is always exactly 42 characters - 2 for the two hash symbols and 40 for the SHA1 string
    var _hashless_string = string_copy(_save_string, 1, string_length(_save_string)-42);
    
    //Make an HMAC hash from the new hashless string
    var _new_hash = sha1_string_utf8_hmac(global.hmac_key, _hashless_string);
    
    //Check if the two hashes match, like before
    if (_expected_hash == _new_hash)
    {
        //Savefile is valid! Let's load the savedata
        load_map = json_decode(_hashless_string);
    }
    else
    {
        show_error("Savefile integrity check failed :(", false);
    }
```

This code is so similar to before that you might miss the differences. All we've done is replace `sha1_string_utf8()`, the internal GameMaker function, with our own new custom script called `sha1_string_utf8_hmac()`. Love it when a plan comes together.

We're using a variable called `global.hmac_key`. As I mentioned above, the HMAC key cannot ever change or all the files that you save will be unreadable. I recommend you define the key as a global variable (or a macro) so that you're never at risk of accidentally changing or losing the HMAC key.

I've glossed over the actual GML implementation of HMAC. It's not a native GameMaker function so you'll need a script to do it. In the project below I've included an implementation of HMAC-SHA1 in GML. All you need to do is copy across the `sha1_string_utf8_hmac()` and `hex_string_byte()` scripts and you've got access to HMAC in your game. The project also includes the example code above: https://www.dropbox.com/s/4yujkgcjdg5pss7/protect%20your%20savefiles.yyz?dl=0

&nbsp;

HMAC is super useful for guaranteeing the authenticity of savefiles, but it does have some drawbacks. If you've been following along closely, you'll notice that savefile hashing does not encrypt or obfuscate the data in the file whatsoever. Everyone can read exactly what you're storing, it just stops them from editing what you've saved. If you need to hide and encrypt data then you'll need to use a proper encryption algorithm. Secondly, HMAC in GameMaker isn't the fastest thing in the world so you want to do it only where absolutely necessary i.e. when saving and loading files. Finally, no encryption or copy-protection or security system is entirely hacker-proof. It might take ages for people to crack into your game, but if they're determined then they will get there eventually.

&nbsp;

Times have changed a lot since I was five years old in the mid-90s; we have online services and micro-transactions and DLC and that means protecting your savefiles is more important than ever. I hope this guide helps you write more secure code for your games.

You can find this example (and loads of other useful code) on my GitHub: https://github.com/JujuAdams/protect-your-savefiles

If you run into trouble you can always send me a message on Twitter: https://twitter.com/jujuadams

&nbsp;

*\* The HMAC algorithm is formally defined in 1997's RFC2104. You can find the specification here: https://tools.ietf.org/html/rfc2104*
