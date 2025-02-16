<template>
  <div class="mint-container">
    <h2>🎨 Mint a New NFT</h2>
    <input v-model="nft.title" placeholder="Title" class="input-box" />
    <input
      v-model="nft.traits"
      placeholder="Traits (e.g., Speed, Strength)"
      class="input-box"
    />
    <input
      v-model="nft.rarity"
      placeholder="Rarity (e.g., Rare, Legendary)"
      class="input-box"
    />
    <input
      v-model="nft.price"
      type="number"
      placeholder="Price (ETH)"
      class="input-box"
    />
    <input type="file" @change="handleFileUpload" class="file-input" />
    <button @click="mintNFT" class="mint-btn">Mint NFT</button>
    <p v-if="mintStatus" class="status">{{ mintStatus }}</p>
  </div>
</template>

<script>
import { connectWallet, getContract } from "../web3";
import axios from "axios";
import { ethers } from "ethers";

export default {
  data() {
    return {
      nft: {
        title: "",
        traits: "",
        rarity: "",
        price: "",
        file: null,
      },
      mintStatus: "",
    };
  },
  methods: {
    async handleFileUpload(event) {
      this.nft.file = event.target.files[0];
    },
    async uploadToIPFS() {
      if (!this.nft.file) {
        alert("Please upload an image!");
        return null;
      }

      const fileName = this.nft.file.name.split(".")[0]; // Extract filename without extension
      const formData = new FormData();
      formData.append("file", this.nft.file);

      try {
        //  Upload Image to Pinata with custom name
        const imageResponse = await axios.post(
          "https://api.pinata.cloud/pinning/pinFileToIPFS",
          formData,
          {
            headers: {
              "Content-Type": "multipart/form-data",
              pinata_api_key: "e7924320163fdb25fb2f",
              pinata_secret_api_key:
                "c7f9d169d4f59dcd164ff7bcbc086eb93df8335bd0dc908d47cbaacfbbc86e65",
            },
            params: {
              pinataMetadata: { name: fileName },
              pinataOptions: { cidVersion: 1 },
            },
          }
        );

        const imageUrl = `https://gateway.pinata.cloud/ipfs/${imageResponse.data.IpfsHash}`;

        // Create NFT Metadata
        const metadata = {
          name: this.nft.title,
          description: `An exclusive NFT with traits: ${this.nft.traits} and rarity: ${this.nft.rarity}`,
          image: imageUrl,
          attributes: [
            { trait_type: "Traits", value: this.nft.traits },
            { trait_type: "Rarity", value: this.nft.rarity },
          ],
        };

        const metadataBlob = new Blob([JSON.stringify(metadata)], {
          type: "application/json",
        });
        const metadataFormData = new FormData();
        metadataFormData.append("file", metadataBlob, `${fileName}.json`);

        const metadataResponse = await axios.post(
          "https://api.pinata.cloud/pinning/pinFileToIPFS",
          metadataFormData,
          {
            headers: {
              "Content-Type": "multipart/form-data",
              pinata_api_key: "e7924320163fdb25fb2f",
              pinata_secret_api_key:
                "c7f9d169d4f59dcd164ff7bcbc086eb93df8335bd0dc908d47cbaacfbbc86e65",
            },
            params: {
              pinataMetadata: { name: `${fileName}.json` },
              pinataOptions: { cidVersion: 1 },
            },
          }
        );
        // // Upload Metadata JSON to Pinata with a custom name (e.g., "1.json")
        // const metadataResponse = await axios.post(
        //   "https://api.pinata.cloud/pinning/pinJSONToIPFS",
        //   metadata,
        //   {
        //     headers: {
        //       pinata_api_key: "e7924320163fdb25fb2f",
        //       pinata_secret_api_key:
        //         "c7f9d169d4f59dcd164ff7bcbc086eb93df8335bd0dc908d47cbaacfbbc86e65",
        //     },
        //     pinataMetadata: { name: `${fileName}.json` },
        //     pinataOptions: { cidVersion: 1 },
        //   }
        // );

        return `https://gateway.pinata.cloud/ipfs/${metadataResponse.data.IpfsHash}`;
      } catch (error) {
        console.error("IPFS Upload Error:", error);
        alert("Failed to upload NFT metadata to IPFS.");
        return null;
      }
    },
    async mintNFT() {
      try {
        this.mintStatus = "Uploading NFT metadata to IPFS...";
        const tokenURI = await this.uploadToIPFS();
        if (!tokenURI) return;

        const { signer } = await connectWallet();
        const contract = await getContract(signer);

        const priceInWei = ethers.parseEther(String(this.nft.price)); //  Convert price to string before parsing
        const txn = await contract.mintNFT(
          tokenURI,
          priceInWei,
          this.nft.rarity,
          this.nft.traits
        );
        await txn.wait();

        this.mintStatus = " NFT Minted Successfully!";
      } catch (error) {
        console.error("Minting Error:", error);
        this.mintStatus = "❌ Error minting NFT.";
      }
    },
  },
};
</script>

<style>
/* Centered Full-Screen Mint Section */
.mint-container {
  max-width: 500px;
  text-align: center;
  background: #222;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0px 4px 10px rgba(255, 255, 255, 0.1);
  display: flex;
  flex-direction: column;
  align-items: center;
}

h2 {
  color: #6a00ff;
  font-size: 1.7rem;
  margin-bottom: 15px;
}

/* Input Boxes */
.input-box {
  width: 100%;
  padding: 12px;
  margin: 10px 0;
  border: 1px solid #6a00ff;
  border-radius: 6px;
  background: #333;
  color: white;
}

/* File Input */
.file-input {
  margin: 10px 0;
  padding: 8px;
  background: #444;
  border-radius: 6px;
  color: white;
}

/* Mint Button */
.mint-btn {
  width: 100%;
  padding: 12px;
  background: #6a00ff;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1.1rem;
  transition: 0.3s;
}

.mint-btn:hover {
  background: #4e00c2;
}

/* Status Message */
.status {
  margin-top: 15px;
  font-weight: bold;
  color: #00ff00;
}
</style>
