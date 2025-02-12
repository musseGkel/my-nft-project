<template>
  <div class="container">
    <h1>Mint Your NFT</h1>
    <button @click="connectWallet">
      {{ walletConnected ? "Wallet Connected" : "Connect Wallet" }}
    </button>

    <input v-model="nftURL" placeholder="Enter IPFS Metadata URL" />
    <button @click="mintNFT">Mint NFT</button>

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

      try {
        const txn = await contract.value.mintNFT(
          await signer.value.getAddress(),
          nftURL.value
        );
        await txn.wait();
        transactionHash.value = txn.hash;
      } catch (error) {
        console.error("Minting failed", error);
        alert("Minting failed. Check console for details.");
      }
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
}
</style>
