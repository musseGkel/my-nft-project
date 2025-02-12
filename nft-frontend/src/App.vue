<template>
  <div class="container">
    <h1>Mint, List & Buy NFTs</h1>

    <!-- Wallet Connection -->
    <button @click="connectWallet" :disabled="isLoading">
      {{ walletConnected ? "Wallet Connected" : "Connect Wallet" }}
    </button>

    <!-- Mint NFT Section -->
    <div v-if="walletConnected">
      <h2>Mint Your NFT</h2>
      <input v-model="nftURL" placeholder="Enter IPFS Metadata URL" />
      <input
        v-model="nftRarity"
        placeholder="Enter Rarity (e.g., Rare, Epic)"
      />
      <input v-model="nftTraits" placeholder="Enter Traits (comma-separated)" />
      <input
        v-model.number="nftPrice"
        type="number"
        placeholder="Enter Price in ETH"
      />
      <button @click="mintNFT" :disabled="isLoading">
        <span v-if="isLoading" class="loader"></span>
        <span v-else>Mint NFT</span>
      </button>
      <p v-if="transactionHash">
        Transaction:
        <a :href="transactionLink" target="_blank">{{ transactionHash }}</a>
      </p>
    </div>

    <!-- Owned NFTs Section -->
    <div v-if="walletConnected">
      <h2>Your NFTs</h2>
      <div v-for="nft in ownedNFTs" :key="nft.id" class="nft-card">
        <img :src="nft.uri" alt="NFT Image" />
        <p><strong>ID:</strong> {{ nft.id }}</p>
        <p><strong>Rarity:</strong> {{ nft.rarity }}</p>
        <p><strong>Traits:</strong> {{ nft.traits }}</p>
        <p>
          <strong>Price:</strong>
          {{ nft.price > 0 ? nft.price + " ETH" : "Not for Sale" }}
        </p>
        <button v-if="!nft.isListed" @click="listNFT(nft.id, nft.price)">
          List for Sale
        </button>
        <button v-else disabled>Listed</button>
      </div>
    </div>

    <!-- Marketplace (Buy NFTs) -->
    <div v-if="walletConnected">
      <h2>Buy NFTs</h2>
      <div v-for="nft in marketNFTs" :key="nft.id" class="nft-card">
        <img :src="nft.uri" alt="NFT Image" />
        <p><strong>ID:</strong> {{ nft.id }}</p>
        <p><strong>Rarity:</strong> {{ nft.rarity }}</p>
        <p><strong>Traits:</strong> {{ nft.traits }}</p>
        <p><strong>Price:</strong> {{ nft.price }} ETH</p>
        <button @click="buyNFT(nft.id, nft.price)">Buy</button>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed } from "vue";
import { ethers } from "ethers";
import contractABI from "./NFTMarketplace.json"; // Ensure ABI is correct

export default {
  setup() {
    const walletConnected = ref(false);
    const provider = ref(null);
    const signer = ref(null);
    const contract = ref(null);
    const nftURL = ref("");
    const nftRarity = ref("");
    const nftTraits = ref("");
    const nftPrice = ref(null);
    const transactionHash = ref("");
    const isLoading = ref(false);
    const ownedNFTs = ref([]);
    const marketNFTs = ref([]);

    const contractAddress = "0x243c644755928231bC1ec8DCE4167C65C65d3FFA";

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

        if (!accounts.length) {
          alert("No accounts found. Please check MetaMask.");
          return;
        }

        // Initialize provider & signer correctly
        const providerInstance = new ethers.BrowserProvider(window.ethereum);
        await providerInstance.ready; // Ensures provider is fully ready

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
      if (
        !nftURL.value ||
        !nftRarity.value ||
        !nftTraits.value ||
        nftPrice.value <= 0
      ) {
        return alert("Please enter all fields correctly.");
      }

      isLoading.value = true;

      try {
        const txn = await contract.value.mintNFT(
          nftURL.value,
          ethers.parseEther(nftPrice.value.toString()),
          nftRarity.value,
          nftTraits.value
        );
        await txn.wait();
        transactionHash.value = txn.hash;

        fetchOwnedNFTs();
      } catch (error) {
        alert(error.code === 4001 ? "User rejected action" : "Minting Failed");
      }

      isLoading.value = false;
    };

    const listNFT = async (tokenId, price) => {
      if (!walletConnected.value) return alert("Connect your wallet first.");
      isLoading.value = true;

      try {
        const txn = await contract.value.listNFT(
          tokenId,
          ethers.parseEther(price.toString())
        );
        await txn.wait();
        fetchOwnedNFTs();
        fetchMarketNFTs();
      } catch (error) {
        alert(error.code === 4001 ? "User rejected action" : "Listing Failed");
      }

      isLoading.value = false;
    };

    const buyNFT = async (tokenId, price) => {
      if (!walletConnected.value) return alert("Connect your wallet first.");
      isLoading.value = true;

      try {
        const txn = await contract.value.buyNFT(tokenId, {
          value: ethers.parseEther(price.toString()),
        });
        await txn.wait();
        fetchOwnedNFTs();
        fetchMarketNFTs();
      } catch (error) {
        alert(error.code === 4001 ? "User rejected action" : "Purchase Failed");
      }

      isLoading.value = false;
    };

    const fetchOwnedNFTs = async () => {
      if (!contract.value) return;
      const totalSupply = await contract.value.totalSupply();
      const userAddress = await signer.value.getAddress();
      ownedNFTs.value = [];

      for (let i = 1; i <= totalSupply; i++) {
        try {
          const owner = await contract.value.ownerOf(i);
          if (owner.toLowerCase() === userAddress.toLowerCase()) {
            const nft = await contract.value.nfts(i);
            ownedNFTs.value.push({ id: i, ...nft });
          }
        } catch (e) {}
      }
    };

    const fetchMarketNFTs = async () => {
      if (!contract.value) return;
      const totalSupply = await contract.value.totalSupply();
      marketNFTs.value = [];

      for (let i = 1; i <= totalSupply; i++) {
        try {
          const nft = await contract.value.nfts(i);
          if (nft.isListed) {
            marketNFTs.value.push({ id: i, ...nft });
          }
        } catch (e) {}
      }
    };

    return {
      connectWallet,
      mintNFT,
      listNFT,
      buyNFT,
      walletConnected,
      nftURL,
      nftRarity,
      nftTraits,
      nftPrice,
      transactionHash,
      isLoading,
      transactionLink: computed(() =>
        transactionHash.value
          ? `https://sepolia.etherscan.io/tx/${transactionHash.value}`
          : "#"
      ),
      ownedNFTs,
      marketNFTs,
    };
  },
};
</script>

<style>
/* Same CSS as before */
</style>
