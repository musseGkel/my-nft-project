<template>
  <div class="marketplace">
    <h2>Available NFTs</h2>
    <div v-if="loading">Loading...</div>
    <div v-else class="nft-list">
      <div v-for="nft in nfts" :key="nft.id" class="nft-card">
        <img :src="nft.image" height="100" width="100" alt="NFT Image" />
        <h3>{{ nft.title }}</h3>
        <p><strong>Rarity:</strong> {{ nft.rarity }}</p>
        <p><strong>Traits:</strong> {{ nft.traits }}</p>
        <p><strong>Price:</strong> {{ nft.price }} ETH</p>
        <button
          v-if="!nft.isListed && nft.owner === userAddress"
          @click="listNFT(nft.id, nft.price)"
        >
          List NFT
        </button>
        <button
          v-if="nft.isListed && nft.owner === userAddress"
          @click="delistNFT(nft.id)"
        >
          Delist NFT
        </button>
        <button
          v-if="nft.isListed && nft.owner !== userAddress"
          @click="buyNFT(nft.id, nft.price)"
        >
          Buy
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { connectWallet, getContract } from "../web3";
import { ethers } from "ethers";
import axios from "axios";

export default {
  data() {
    return {
      nfts: [],
      loading: true,
      userAddress: null,
    };
  },
  async mounted() {
    await this.loadNFTs();
  },
  methods: {
    async loadNFTs() {
      try {
        console.log("🔍 Fetching NFTs...");
        this.loading = true;

        const { signer } = await connectWallet();
        this.userAddress = await signer.getAddress(); // Fetch and store the wallet address
        console.log("Wallet Connected:", await signer.getAddress());

        const contract = await getContract(signer);
        console.log("Smart Contract Loaded at:", contract.target);

        // Fetch Minted Events
        const nftEvents = await contract.queryFilter(contract.filters.Minted());
        console.log(`📊 Found ${nftEvents.length} Minted NFTs`);

        const nftsArray = [];

        for (let event of nftEvents) {
          const tokenId = Number(event.args[0]); // Convert BigInt to Number
          console.log(`🔹 Processing NFT Token ID: ${tokenId}`);

          const nft = await contract.nfts(tokenId);
          console.log(`📜 NFT Data (ID: ${tokenId}):`, nft);

          const currentOwner = await contract.ownerOf(tokenId); // ✅ Fetch updated owner

          // ✅ Ensure the NFT is either listed or owned by the user
          if (
            !nft.isListed &&
            currentOwner.toLowerCase() !== this.userAddress.toLowerCase()
          ) {
            console.warn(
              `⚠️ Skipping NFT ${tokenId} (Not Listed & Not Owned by User)`
            );
            continue;
          }

          // // If the NFT is NOT listed and NOT owned by the current user, skip it
          // if (
          //   !nft.isListed &&
          //   nft.creator.toLowerCase() !== this.userAddress.toLowerCase()
          // ) {
          //   console.warn(
          //     `⚠️ Skipping Unlisted NFT ${tokenId} (Not Owned by User)`
          //   );
          //   continue;
          // }

          if (nft.creator === "0x0000000000000000000000000000000000000000") {
            console.warn(`⚠️ Skipping NFT ${tokenId} (Not Minted)`);
            continue;
          }

          console.log(`🌍 Fetching Metadata from: ${nft.uri}`);
          try {
            const ipfsGateway =
              "https://harlequin-naval-tiglon-67.mypinata.cloud/ipfs/";
            const metadataURL = nft.uri.replace(
              "https://gateway.pinata.cloud/ipfs/",
              ipfsGateway
            );

            console.log(`🔄 Trying alternative IPFS Gateway: ${metadataURL}`);

            const metadataResponse = await axios.get(metadataURL, {
              headers: { Accept: "application/json" },
            });

            const metadata = metadataResponse.data;

            // Replace the default Pinata gateway in metadata image URL
            const imageUrl = metadata.image.replace(
              "https://gateway.pinata.cloud/ipfs/",
              ipfsGateway
            );

            console.log(
              `🖼️ Adjusted Image URL for NFT ${tokenId}: ${imageUrl}`
            );

            nftsArray.push({
              id: tokenId,
              title: metadata.name,
              image: imageUrl,
              traits:
                metadata.attributes.find((attr) => attr.trait_type === "Traits")
                  ?.value || "Unknown",
              rarity:
                metadata.attributes.find((attr) => attr.trait_type === "Rarity")
                  ?.value || "Unknown",
              price: ethers.formatEther(nft.price),
              isListed: nft.isListed,
              creator: nft.creator,
              owner: currentOwner,
            });
          } catch (metadataError) {
            console.error(
              `❌ Failed to fetch metadata for NFT ${tokenId}:`,
              metadataError
            );
          }
        }

        this.nfts = nftsArray;
        this.loading = false;
        console.log("🎉 Successfully loaded NFTs!", this.nfts);
      } catch (error) {
        console.error("❌ Error fetching NFTs:", error);
        this.loading = false;
      }
    },
    async listNFT(tokenId, price) {
      try {
        console.log(`🔹 Listing NFT ${tokenId} for price:`, price);

        if (!price || isNaN(price)) {
          alert("⚠️ Price must be a valid number.");
          return;
        }

        const { signer } = await connectWallet();
        const contract = await getContract(signer);

        console.log("✅ Calling listNFT on contract with:", {
          tokenId,
          price: ethers.parseEther(price.toString()),
        });

        const txn = await contract.listNFT(
          tokenId,
          ethers.parseEther(price.toString())
        ); // Convert ETH to Wei
        await txn.wait();

        alert("NFT Listed Successfully!");
        await this.loadNFTs(); // Refresh Marketplace
      } catch (error) {
        console.error(`❌ Failed to list NFT ${tokenId}:`, error);
        alert("⚠️ Error listing NFT.");
      }
    },
    async buyNFT(tokenId, price) {
      const { signer } = await connectWallet();
      const contract = await getContract(signer);
      const txn = await contract.buyNFT(tokenId, {
        value: ethers.parseEther(price),
      });
      await txn.wait();
      alert("NFT Purchased!");
      await this.loadNFTs();
    },

    async delistNFT(tokenId) {
      try {
        console.log(`Attempting to delist NFT ${tokenId}`);
        const { signer } = await connectWallet();
        const userAddress = await signer.getAddress();
        const contract = await getContract(signer);

        // Check ownership before delisting
        const nftOwner = await contract.ownerOf(tokenId);
        if (nftOwner.toLowerCase() !== userAddress.toLowerCase()) {
          alert("You can only delist NFTs you own.");
          return;
        }

        const txn = await contract.delistNFT(tokenId);
        await txn.wait();

        alert("NFT Delisted Successfully!");
        await this.loadNFTs(); // Refresh marketplace
      } catch (error) {
        console.error(`Failed to delist NFT ${tokenId}:`, error);
        alert("⚠️ Error delisting NFT.");
      }
    },
  },
};
</script>

<style>
.nft-list {
  display: grid;
  grid-template-columns: repeat(auto-fit);
  gap: 20px; /* Adds spacing between NFTs */
  padding: 20px;
  max-width: 1200px; /* Prevents too wide layouts */
  margin: auto; /* Centers the NFT grid */
}

.nft-card {
  background: #222;
  border-radius: 10px;
  padding: 15px;
  text-align: center;
  box-shadow: 0px 4px 10px rgba(255, 255, 255, 0.1);
  width: 100%;
}

.nft-card img {
  width: 100%;
  height: auto;
  border-radius: 8px;
}

button {
  margin-top: 10px;
  width: 100%;
  padding: 10px;
  background: #6a00ff;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 1rem;
  transition: 0.3s;
}

button:hover {
  background: #4e00c2;
}
</style>
