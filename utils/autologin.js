// ==UserScript==
// @name         Portainer Auto Login
// @namespace    arsscriptum.local served from https://arsscriptum.ca/utils/autologin.js
// @version      1.0
// @description  Decrypts an AES-GCM credential blob (salt|iv|tag|cipher, base64) using a PBKDF2-derived key. The passphrase is supplied by the caller, never stored here.
//               Auto-fills and submits the Portainer login form on page load 
// @run-at       document-idle
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    function b64ToBytes(b64) {
        var bin = atob(b64.trim());
        var len = bin.length;
        var out = new Uint8Array(len);
        var i   = 0;
        for (i = 0; i < len; i += 1) {
            out[i] = bin.charCodeAt(i);
        }
        return out;
    }

    async function deriveKey(passphrase, salt) {
        var enc = new TextEncoder();
        var baseKey = await crypto.subtle.importKey(
            'raw', enc.encode(passphrase), 'PBKDF2', false, ['deriveKey']
        );
        return crypto.subtle.deriveKey(
            {
                name: 'PBKDF2',
                salt: salt,
                iterations: 200000,
                hash: 'SHA-256'
            },
            baseKey,
            { name: 'AES-GCM', length: 256 },
            false,
            ['decrypt']
        );
    }

    // blobB64: the base64 contents of data.aes
    // passphrase: the secret the user typed
    // returns { u, p } or throws
    async function decryptCredentials(blobB64, passphrase) {
        var raw  = b64ToBytes(blobB64);
        var salt = raw.slice(0, 16);
        var iv   = raw.slice(16, 28);
        var tag  = raw.slice(28, 44);
        var ct   = raw.slice(44);

        // WebCrypto expects cipher+tag concatenated
        var full = new Uint8Array(ct.length + tag.length);
        full.set(ct, 0);
        full.set(tag, ct.length);

        var key = await deriveKey(passphrase, salt);
        var ptBuf = await crypto.subtle.decrypt(
            { name: 'AES-GCM', iv: iv }, key, full
        );
        var json = new TextDecoder().decode(ptBuf);
        return JSON.parse(json);
    }

    window.ArsAutoLogin = { decryptCredentials: decryptCredentials };
})();
