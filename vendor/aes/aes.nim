when not(defined(AES_H)): 
  const 
    AES_H* = true
  # #define the macros below to 1/0 to enable/disable the mode of operation.
  #
  # CBC enables AES encryption in CBC-mode of operation.
  # CTR enables encryption in counter-mode.
  # ECB enables the basic ECB 16-byte block algorithm. All can be enabled simultaneously.
  # The #ifndef-guard allows it to be configured before #include'ing or at compile time.
  const 
    CBC* = 1
    ECB* = 1
    CTR* = 1
    AES128* = 1
    AES192* = 1
    AES256* = 1
  const 
    AES_BLOCKLEN* = 16
  when defined(AES256) and (AES256 == 1): 
    const 
      AES_KEYLEN* = 32
      AES_keyExpSize* = 240
  elif defined(AES192) and (AES192 == 1): 
    const 
      AES_KEYLEN* = 24
      AES_keyExpSize* = 208
  else: 
    const 
      AES_KEYLEN* = 16
      AES_keyExpSize* = 176
  type 
    AES_ctx* = object 
      RoundKey*: array[AES_keyExpSize, uint8]
      Iv*: array[AES_BLOCKLEN, uint8]
  
  {.push importc, cdecl.}
  proc AES_init_ctx*(ctx: ptr AES_ctx; key: ptr uint8) 
  proc AES_init_ctx_iv*(ctx: ptr AES_ctx; key: ptr uint8; iv: ptr uint8)
  proc AES_ctx_set_iv*(ctx: ptr AES_ctx; iv: ptr uint8)
  when defined(ECB) and (ECB == 1): 
    # buffer size is exactly AES_BLOCKLEN bytes; 
    # you need only AES_init_ctx as IV is not used in ECB 
    # NB: ECB is considered insecure for most uses
    proc AES_ECB_encrypt*(ctx: ptr AES_ctx; buf: ptr uint8)
    proc AES_ECB_decrypt*(ctx: ptr AES_ctx; buf: ptr uint8)
  when defined(CBC) and (CBC == 1): 
    # buffer size MUST be mutile of AES_BLOCKLEN;
    # Suggest https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS7 for padding scheme
    # NOTES: you need to set IV in ctx via AES_init_ctx_iv() or AES_ctx_set_iv()
    #        no IV should ever be reused with the same key 
    proc AES_CBC_encrypt_buffer*(ctx: ptr AES_ctx; buf: ptr uint8; 
                                 length: uint32_t)
    proc AES_CBC_decrypt_buffer*(ctx: ptr AES_ctx; buf: ptr uint8; 
                                 length: uint32_t)
  # Same function for encrypting as for decrypting. 
  # IV is incremented for every block, and used after encryption as XOR-compliment for output
  # Suggesting https://en.wikipedia.org/wiki/Padding_(cryptography)#PKCS7 for padding scheme
  # NOTES: you need to set IV in ctx with AES_init_ctx_iv() or AES_ctx_set_iv()
  #        no IV should ever be reused with the same key 
  proc AES_CTR_xcrypt_buffer*(ctx: ptr AES_ctx; buf: ptr uint8; 
                                length: uint32)
  {.pop.}
