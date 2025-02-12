<template>
  <div class="container">
    <h1>Mint Your NFT</h1>
    <button @click="connectWallet" :disabled="isLoading">
      {{ walletConnected ? "Wallet Connected" : "Connect Wallet" }}
    </button>

    <input v-model="nftURL" placeholder="Enter IPFS Metadata URL" />
    <button @click="mintNFT" :disabled="isLoading">
      <span v-if="isLoading" class="loader"></span>
      <span v-else>Mint NFT</span>
    </button>

    <p v-if="transactionHash">
      Transaction:
      <a :href="transactionLink" target="_blank">{{ transactionHash }}</a>
    </p>
  </div>
</template>

<script>
import { ref, computed } from "vue";
import { ethers } from "ethers";
import contractABI from "./MyNFT.json"; // Ensure ABI is stored here

export default {
  setup() {
    const walletConnected = ref(false);
    const provider = ref(null);
    const signer = ref(null);
    const contract = ref(null);
    const nftURL = ref("");
    const transactionHash = ref("");
    const isLoading = ref(false); // NEW: Loading state

    const contractAddress = "0xD0e47518376DAD11aC29Df19000545b814e453ab"; // Replace with the new contract address

    const connectWallet = async () => {
      if (!window.ethereum) {
        alert("MetaMask is not installed. Please install MetaMask.");
        return;
      }

      try {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });

        const providerInstance = new ethers.BrowserProvider(window.ethereum);
        const signerInstance = await providerInstance.getSigner();

        provider.value = providerInstance;
        signer.value = signerInstance;
        contract.value = new ethers.Contract(
          contractAddress,
          contractABI.abi,
          signerInstance
        );

        walletConnected.value = true;
        alert(`Wallet Connected: ${accounts[0]}`);
      } catch (error) {
        console.error("Wallet connection failed:", error);

        if (error.code === -32002) {
          alert("Please unlock MetaMask and approve the pending request.");
        } else {
          alert(`Failed to connect wallet: ${error.message}`);
        }
      }
    };

    const mintNFT = async () => {
      if (!walletConnected.value) return alert("Connect your wallet first.");
      if (!nftURL.value) return alert("Enter a valid IPFS Metadata URL.");

      isLoading.value = true; // Start loading

      try {
        const txn = await contract.value.mintNFT(
          await signer.value.getAddress(),
          nftURL.value
        );
        await txn.wait();
        transactionHash.value = txn.hash;
      } catch (error) {
        transactionHash.value = "";

        const errorMessage =
          error?.reason ||
          error?.message ||
          error?.error?.message ||
          JSON.stringify(error);

        if (error.code === -32002) {
          alert("Please unlock MetaMask and approve the pending request.");
        } else if (error.code === 4001) {
          alert("User rejected action");
        } else {
          alert(`Minting Failed`);
        }
      }
      isLoading.value = false; // Stop loading
    };

    const transactionLink = computed(() => {
      return transactionHash.value
        ? `https://sepolia.etherscan.io/tx/${transactionHash.value}`
        : "#";
    });

    return {
      connectWallet,
      mintNFT,
      walletConnected,
      nftURL,
      transactionHash,
      isLoading,
      transactionLink,
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
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 120px;
}
button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
.loader {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 20px;
  height: 20px;
  animation: spin 1s linear infinite;
  display: inline-block;
}
@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
