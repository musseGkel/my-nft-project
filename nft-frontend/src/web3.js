import { ethers } from "ethers";
import contractABI from "./NFTMarketplace.json";

const contractAddress = "0x243c644755928231bC1ec8DCE4167C65C65d3FFA"; // Replace with deployed contract address

export async function connectWallet() {
  try {
    if (typeof window.ethereum === "undefined") {
      alert("MetaMask not detected. Please install MetaMask.");
      throw new Error("No crypto wallet found");
    }

    // Request account access
    await window.ethereum.request({ method: "eth_requestAccounts" });

    const provider = new ethers.BrowserProvider(window.ethereum); // ✅ Fixed: Use `BrowserProvider` instead of `Web3Provider`
    const signer = await provider.getSigner();
    const address = await signer.getAddress();

    console.log("Connected wallet:", address);
    return { provider, signer, address };
  } catch (error) {
    console.error("Wallet connection error:", error);
    alert(
      "Failed to connect wallet. Make sure MetaMask is installed and you are logged in."
    );
  }
}

export async function getContract(signer) {
  return new ethers.Contract(contractAddress, contractABI, signer);
}
