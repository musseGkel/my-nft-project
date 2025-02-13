<template>
  <div class="marketplace">
    <h2>Available NFTs</h2>
    <div v-if="loading">Loading...</div>
    <div v-else class="nft-list">
      <div v-for="nft in nfts" :key="nft.id" class="nft-card">
        <img :src="nft.uri" alt="NFT Image" />
        <h3>{{ nft.title }}</h3>
        <p><strong>Rarity:</strong> {{ nft.rarity }}</p>
        <p><strong>Traits:</strong> {{ nft.traits }}</p>
        <p><strong>Price:</strong> {{ nft.price }} ETH</p>
        <button v-if="!nft.isListed" @click="listNFT(nft.id, nft.price)">
          List NFT
        </button>
        <button v-if="nft.isListed" @click="buyNFT(nft.id, nft.price)">
          Buy
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { connectWallet, getContract } from "../web3";
import { ethers } from "ethers";

export default {
  data() {
    return {
      nfts: [],
      loading: true,
    };
  },
  async mounted() {
    await this.loadNFTs();
  },
  methods: {
    async loadNFTs() {
      try {
        this.loading = true;
        const { signer } = await connectWallet();
        const contract = await getContract(signer);

        const nftEvents = await contract.queryFilter(contract.filters.Minted());
        const nftsArray = [];

        for (let event of nftEvents) {
          const tokenId = Number(event.args[0]); // ✅ Convert BigInt to Number properly
          const nft = await contract.nfts(tokenId);

          if (nft.creator === "0x0000000000000000000000000000000000000000") {
            continue;
          }

          const metadataResponse = await fetch(nft.uri);
          const metadata = await metadataResponse.json();

          nftsArray.push({
            id: tokenId,
            title: metadata.name,
            image: metadata.image,
            traits:
              metadata.attributes.find((attr) => attr.trait_type === "Traits")
                ?.value || "Unknown",
            rarity:
              metadata.attributes.find((attr) => attr.trait_type === "Rarity")
                ?.value || "Unknown",
            price: ethers.formatEther(nft.price),
            isListed: nft.isListed,
          });
        }

        this.nfts = nftsArray;
        this.loading = false;
      } catch (error) {
        console.error("Error fetching NFTs:", error);
        this.loading = false;
      }
    },
    async listNFT(tokenId, price) {
      const { signer } = await connectWallet();
      const contract = await getContract(signer);
      const txn = await contract.listNFT(
        tokenId,
        ethers.utils.parseEther(price)
      );
      await txn.wait();
      alert("NFT Listed!");
      await this.loadNFTs();
    },
    async buyNFT(tokenId, price) {
      const { signer } = await connectWallet();
      const contract = await getContract(signer);
      const txn = await contract.buyNFT(tokenId, {
        value: ethers.utils.parseEther(price),
      });
      await txn.wait();
      alert("NFT Purchased!");
      await this.loadNFTs();
    },
  },
};
</script>

<style>
.marketplace {
  max-width: 800px;
  margin: auto;
}
.nft-list {
  display: flex;
  flex-wrap: wrap;
}
.nft-card {
  border: 1px solid #ddd;
  padding: 10px;
  margin: 10px;
  text-align: center;
}
</style>
