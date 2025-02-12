<template>
  <div class="container">
    <h1>Mint Your NFT</h1>
    <button @click="connectWallet">
      {{ walletConnected ? "Wallet Connected" : "Connect Wallet" }}
    </button>

    <input v-model="nftURL" placeholder="Enter IPFS URL" />
    <button @click="mintNFT">Mint NFT</button>

    <p v-if="transactionHash">
      Transaction:
      <a :href="transactionLink" target="_blank">{{ transactionHash }}</a>
    </p>
  </div>
</template>

<script>
import { ref } from "vue";
import { ethers } from "ethers";
import contractABI from "./MyNFT.json"; // Store ABI in src/MyNFT.json

export default {
  setup() {
    const walletConnected = ref(false);
    const provider = ref(null);
    const signer = ref(null);
    const contract = ref(null);
    const nftURL = ref("");
    const transactionHash = ref("");

    const contractAddress = "0x7447a8B37De9DbE1DB89091A7066ff7ee9494e76"; // Replace with your contract address

    const connectWallet = async () => {
      if (!window.ethereum) {
        alert("MetaMask is not installed. Please install MetaMask.");
        return;
      }

      try {
        // Request account access
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });

        // Create provider and signer
        const providerInstance = new ethers.BrowserProvider(window.ethereum);
        const signerInstance = await providerInstance.getSigner();

        provider.value = providerInstance;
        signer.value = signerInstance;
        contract.value = new ethers.Contract(
          contractAddress,
          contractABI.abi,
          signerInstance
        );

        // Store connected wallet address
        walletConnected.value = true;
        alert(`Wallet Connected: ${accounts[0]}`);
      } catch (error) {
        console.error("Wallet connection failed:", error);

        // Handle "Pending Request" error (code -32002)
        if (error.code === -32002) {
          alert("Please unlock MetaMask and approve the pending request.");
        } else {
          alert(`Failed to connect wallet: ${error.message}`);
        }
      }
    };

    const mintNFT = async () => {
      if (!walletConnected.value) return alert("Connect your wallet first.");
      if (!nftURL.value) return alert("Enter an IPFS URL.");

      try {
        const txn = await contract.value.mintNFT(
          await signer.value.getAddress(),
          nftURL.value
        );
        await txn.wait();
        transactionHash.value = txn.hash;
      } catch (error) {
        console.error("Minting failed", error);
      }
    };

    return {
      connectWallet,
      mintNFT,
      walletConnected,
      nftURL,
      transactionHash,
      transactionLink: `https://sepolia.etherscan.io/tx/${transactionHash.value}`,
    };
  },
};
</script>

<style>
.container {
  text-align: center;
  margin-top: 50px;
}
input {
  margin: 10px;
  padding: 8px;
  width: 300px;
}
button {
  padding: 10px;
  margin: 10px;
  cursor: pointer;
}
</style>
