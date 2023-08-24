---
layout: post
title:  "Securing Credentials used in PowerShell Scripts"
summary: "Quick&Easy Solution to Store User Credentials for Authentication in Scripts"
author: guillaume
date: '2023-03-06'
category: ['powershell','scripts', 'encryption', 'security', 'credentials']
tags: powershell, scripts, encryption, credentials, security
thumbnail: /assets/img/posts/securecreds/main.png
keywords: encryption, powershell
usemathjax: false
permalink: /blog/securing-scripts-credentials/

---

### Encryption Demo in PowerShell using a simple GUI </h3>



---------------------------------------------------------------------------------------------------------

This PowerShell scripts demos encryption. I wrote this because a [user](https://www.reddit.com/user/Anonymus123GH/) on Reddit needed some help and I though it might
be nice for them to have. Here's the [post](https://www.reddit.com/r/PowerShell/comments/ymokeh/how_to_remove_the_dot_in_decimals/). Also, I was bored.


#### How To Use 

```
    .\Show-CipherDialog.ps1
```

---------------------------------------------------------------------------------------------------------


[HowTo](https://arssciptum.github.io/assets/img/posts/encryption/ciphers.png)


- Launch 
- Choose cipher 
- Write text
- GO 


---------------------------------------------------------------


### Ciphers Defined in JSON 

#### JSON file 

```json

    [
      {
        "Cipher": "Caesar Encrypt",
        "File": "CaesarEncrypt.ps1"
      },
      {
        "Cipher": "Caesar Decrypt",
        "File": "CaesarDecrypt.ps1"
      },
      {
        "Cipher": "DES_Encrypt",
        "File": "DES_Encrypt.ps1"
      },
      {
        "Cipher": "DES_Decrypt",
        "File": "DES_Decrypt.ps1"
      },
      {
        "Cipher": "AES_Encrypt",
        "File": "AesEncrypt.ps1"
      },
      {
        "Cipher": "AES_Decrypt",
        "File": "AesDecrypt.ps1"
      }
    ]


```

---------------------------------------------------------------



### Ciphers in PowerShell: defined in C# type 

#### AES : defined in C# type 


```cs
         
    using System;
    using System.IO;
    using System.Security.Cryptography;
    using System.Text;

    namespace Cryptography {
        public static class AES {
            public static String Encrypt(string input, string password)
            {
                // Get the bytes of the string
                byte[] bytesToBeEncrypted = Encoding.UTF8.GetBytes(input);
                byte[] passwordBytes = Encoding.UTF8.GetBytes(password);

                // Hash the password with SHA256
                passwordBytes = SHA256.Create().ComputeHash(passwordBytes);

                byte[] bytesEncrypted = EncryptStringToBytes(input, passwordBytes);

                string result = Convert.ToBase64String(bytesEncrypted);

                return result;
            }

            public static String Decrypt(string input, string password)
            {
                // Get the bytes of the string
                byte[] bytesToBeDecrypted = Convert.FromBase64String(input);
                byte[] passwordBytes = Encoding.UTF8.GetBytes(password);
                passwordBytes = SHA256.Create().ComputeHash(passwordBytes);

                string result = DecryptStringFromBytes(bytesToBeDecrypted, passwordBytes);

                return result;
            }

            static byte[] EncryptStringToBytes(string str, byte[] keys)
            {
                byte[] encrypted;
                using (var aes = Aes.Create())
                {
                    aes.Key = keys;

                    aes.GenerateIV(); // The get method of the 'IV' property of the 'SymmetricAlgorithm' automatically generates an IV if it is has not been generate before. 

                 
                    aes.Padding = PaddingMode.PKCS7;
                    
                    using (MemoryStream msEncrypt = new MemoryStream())
                    {
                        msEncrypt.Write(aes.IV, 0, aes.IV.Length);
                        ICryptoTransform encoder = aes.CreateEncryptor();
                        using (CryptoStream csEncrypt = new CryptoStream(msEncrypt, encoder, CryptoStreamMode.Write))
                        using (StreamWriter swEncrypt = new StreamWriter(csEncrypt))
                        {
                            swEncrypt.Write(str);
                        }
                        encrypted = msEncrypt.ToArray();
                    }
                }

                return encrypted;
            }

            static string DecryptStringFromBytes(byte[] cipherText, byte[] key)
            {
                string decrypted;
                using (var aes = Aes.Create())
                {
                    aes.Key = key;
                    aes.Padding = PaddingMode.PKCS7;

                    using (MemoryStream msDecryptor = new MemoryStream(cipherText))
                    {
                        byte[] readIV = new byte[16];
                        msDecryptor.Read(readIV, 0, 16);
                        aes.IV = readIV;
                        ICryptoTransform decoder = aes.CreateDecryptor();
                        using (CryptoStream csDecryptor = new CryptoStream(msDecryptor, decoder, CryptoStreamMode.Read))
                        using (StreamReader srReader = new StreamReader(csDecryptor))
                        {
                            decrypted = srReader.ReadToEnd();
                        }
                    }
                }
                return decrypted;
            }
        }
    }

```

#### Caesar : defined in C# type

```cs
    using System;
    using System.Text;
    namespace Cryptography {
        public static class Caesar
        {
            public static String Encrypt(String text, String pass)
            {
                var passwordBytes = Encoding.UTF8.GetBytes(pass);
                var cipherBytes = Encipher(passwordBytes, Encoding.UTF8.GetBytes(text));
                var cipherText = Convert.ToBase64String(cipherBytes);
                return cipherText;
            }
            public static String Decrypt(String cipherText, String pass)
            {
                var passwordBytes = Encoding.UTF8.GetBytes(pass);
                var plaintext = Encoding.UTF8.GetString(Decipher(passwordBytes, Convert.FromBase64String(cipherText)));
                return plaintext;
            }
            private static byte[] Encipher(byte[] key, byte[] plaindata)
            {
                return Crypt(key, plaindata, 1);
            }

            private static byte[] Decipher(byte[] key, byte[] cipherdata)
            {
                return Crypt(key, cipherdata, -1);
            }

           
            static byte[] Crypt(byte[] key, byte[] dataIn, int switcher)
            {
                //Initialize return array at same length as incoming array
                var dataOut = new byte[dataIn.Length];

                var i = 0;
                var u = 0;
                var mod = dataIn.Length % key.Length;

                for (; i < dataIn.Length - mod; i = i + key.Length ){
                    for (u = 0; u < key.Length; u++){
                        var c = dataIn[i + u];
                        c = (byte)(c + (key[u] * switcher));
                        dataOut[i + u] = c;
                    }
                }

                if (u == key.Length) u = 0;

                //Second pass: Iterate over the remaining bytes beyond the final block.
                for (; i < dataIn.Length; i++){
                    var c = dataIn[i];
                    c = (byte)(c + (key[u] * switcher));
                    dataOut[i] = c;
                    u++;
                }

                return dataOut;
            }
        }
    }

```


---------------------------------------------------------------------------------------------------------


## Get the code 


[EncryptionDialog on GitHub](https://github.com/arsscriptum/PowerShell.EncryptionDialog)