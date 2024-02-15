package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/binary"
	"fmt"

	"golang.org/x/crypto/bcrypt"
	"golang.org/x/crypto/scrypt"
)

// Generate 16 bytes randomly and securely using the
// Cryptographically secure pseudorandom number generator (CSPRNG)
// in the crypto.rand package
func GenerateRandomSalt(saltSize int) []byte {
	var salt = make([]byte, saltSize)

	_, err := rand.Read(salt[:])

	if err != nil {
		panic(err)
	}

	return salt
}

func HashPassword(password string) (string, error) {
	hashedBytes, err := bcrypt.GenerateFromPassword([]byte(password), 10 /*cost*/)
	if err != nil {
		return "", err
	}

	// Encode the entire thing as base64 and return
	hashBase64 := base64.StdEncoding.EncodeToString(hashedBytes)

	return hashBase64, nil
}

// ComparePassword hashes the test password and then compares
// the two hashes.
func ComparePassword(hashBase64, testPassword string) bool {

	// Decode the real hashed and salted password so we can
	// split out the salt
	hashBytes, err := base64.StdEncoding.DecodeString(hashBase64)
	if err != nil {
		fmt.Println("Error, we were given invalid base64 string", err)
		return false
	}

	err = bcrypt.CompareHashAndPassword(hashBytes, []byte(testPassword))
	return err == nil
}

func EncodeUnsealKey(unsealkeyraw string, saltyint int64) ([]byte, error) {

	saltlower := make([]byte, 8)
	saltupper := make([]byte, 8)
	binary.LittleEndian.PutUint64(saltlower, uint64(saltyint))
	binary.BigEndian.PutUint64(saltupper, uint64(saltyint))
	salt := append(saltlower, saltupper...)
	//fmt.Println("Salt:  ", salt)
	unsealkeyencoded, err := scrypt.Key([]byte(unsealkeyraw), salt, 32768, 8, 1, 32)

	return unsealkeyencoded, err
}

func Encode(b []byte) string {
	return base64.StdEncoding.EncodeToString(b)
}
func Decode(s string) []byte {
	data, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		panic(err)
	}
	return data
}

func EncryptSecret(password string, saltyint int64, secret string) (string, error) {
	encryptionkey, err := EncodeUnsealKey(password, saltyint)
	if err != nil {
		panic(err)
	}

	block, err := aes.NewCipher([]byte(encryptionkey))
	if err != nil {
		return "", err
	}
	plainText := []byte(secret)
	saltlower := make([]byte, 8)
	saltupper := make([]byte, 8)
	binary.LittleEndian.PutUint64(saltlower, uint64(saltyint))
	binary.BigEndian.PutUint64(saltupper, uint64(saltyint))
	bytes := append(saltlower, saltupper...)

	cfb := cipher.NewCFBEncrypter(block, bytes)
	cipherText := make([]byte, len(plainText))
	cfb.XORKeyStream(cipherText, plainText)
	return Encode(cipherText), nil
}

func DecryptSecret(password string, saltyint int64, encryptedsecret string) (string, error) {
	encryptionkey, err := EncodeUnsealKey(password, saltyint)
	if err != nil {
		panic(err)
	}

	block, err := aes.NewCipher([]byte(encryptionkey))
	if err != nil {
		return "", err
	}
	saltlower := make([]byte, 8)
	saltupper := make([]byte, 8)
	binary.LittleEndian.PutUint64(saltlower, uint64(saltyint))
	binary.BigEndian.PutUint64(saltupper, uint64(saltyint))
	bytes := append(saltlower, saltupper...)

	cipherText := Decode(encryptedsecret)
	cfb := cipher.NewCFBDecrypter(block, bytes)
	plainText := make([]byte, len(cipherText))
	cfb.XORKeyStream(plainText, cipherText)
	return string(plainText), nil
}
