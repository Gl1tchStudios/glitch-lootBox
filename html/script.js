class CSGOLootBox {
    constructor() {
        this.container = document.getElementById('lootbox-container');
        this.spinner = document.getElementById('spinner');
        this.resultContainer = document.getElementById('result-container');
        this.skipBtn = document.getElementById('skip-btn');
        this.collectBtn = document.getElementById('collect-btn');
        this.closeBtn = document.getElementById('close-btn');
        this.titleElement = document.getElementById('lootbox-title');
        
        this.isSpinning = false;
        this.isOpen = false;
        this.spinnerItems = [];
        this.selectedReward = null;
        this.spinTimeout = null;
        
        this.inventoryConfig = {
            iconPath: 'nui://ox_inventory/web/images/',
            iconExtension: '.png',
            fallbackIcon: 'nui://ox_inventory/web/images/placeholder.png'
        };
        
        this.setupEventListeners();
        this.setupRarityColors();
        this.requestConfig();
    }

    setupEventListeners() {
        this.skipBtn.addEventListener('click', () => this.skipAnimation());
        this.collectBtn.addEventListener('click', () => this.collectReward());
        this.closeBtn.addEventListener('click', () => this.emergencyClose());
        
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' || e.key === 'Backspace') {
                this.emergencyClose();
            }
        });
        
        this.container.addEventListener('click', (e) => {
            if (e.target === this.container) {
                this.emergencyClose();
            }
        });
    }

    setupRarityColors() {
        this.rarityColors = {
            common: '#b0c3d9',     // Light blue/white
            uncommon: '#5e98d9',   // Green
            rare: '#4b69ff',       // Blue
            epic: '#8847ff',       // Purple
            legendary: '#d32ce6',  // Orange/Pink
            mythic: '#eb4b4b'      // Red
        };
    }

    // Request config from client
    requestConfig() {
        fetch(`https://${GetParentResourceName()}/requestConfig`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {
            console.log('Config request failed, using defaults');
        });
    }

    // Update config from client
    updateConfig(config) {
        if (config.ui && config.ui.inventory) {
            this.inventoryConfig = config.ui.inventory;
            console.log('Updated inventory config:', this.inventoryConfig);
        }
        
        if (config.ui && config.ui.rarityColors) {
            this.rarityColors = config.ui.rarityColors;
            console.log('Updated rarity colors:', this.rarityColors);
        }
    }

    // Open the loot box with CSGO-style spinner
    open(spinnerItems, selectedReward) {
        console.log('Opening CSGO loot box with', spinnerItems.length, 'items');
        console.log('Selected reward:', selectedReward);
        
        // Prevent multiple opens
        if (this.isOpen) {
            console.log('UI already open, ignoring');
            return;
        }
        
        this.spinnerItems = spinnerItems;
        this.selectedReward = selectedReward;
        this.isOpen = true;
        
        // Show container
        this.container.classList.remove('hidden');
        this.container.style.display = 'flex';
        this.container.style.visibility = 'visible';
        
        // Set title
        this.titleElement.textContent = 'Opening Ammo Crate...';
        
        // Clear previous items
        this.spinner.innerHTML = '';
        
        // Create spinner items (60 items exactly)
        this.spinnerItems.forEach((itemData, index) => {
            const item = this.createSpinnerItem(itemData, index === 44); // 45th item (0-indexed 44)
            this.spinner.appendChild(item);
            
            // Debug log for the winning item
            if (index === 44) {
                console.log('=== WINNING ITEM VERIFICATION ===');
                console.log('Item at index 44:', itemData);
                console.log('Selected reward:', this.selectedReward);
                console.log('Do they match?', itemData.item === this.selectedReward.item);
                console.log('================================');
            }
        });
        
        // Small delay to ensure DOM is ready, then start spinning
        setTimeout(() => {
            this.startSpin();
        }, 100);
    }

    createSpinnerItem(itemData, isWinning = false) {
        const item = document.createElement('div');
        item.className = `spinner-item ${itemData.rarity}`;
        
        if (isWinning) {
            item.classList.add('winning-item');
        }
        
        // Item content
        const content = document.createElement('div');
        content.className = 'item-content';
        
        const icon = document.createElement('div');
        icon.className = 'item-icon';
        
        // Create image element for inventory item
        const img = document.createElement('img');
        img.src = this.getItemImageUrl(itemData.item);
        img.alt = itemData.label;
        img.onerror = () => {
            // Fallback to placeholder on error
            img.src = this.inventoryConfig.fallbackIcon;
        };
        
        icon.appendChild(img);
        
        const label = document.createElement('div');
        label.className = 'item-label';
        label.textContent = itemData.label;
        
        const rarity = document.createElement('div');
        rarity.className = 'item-rarity';
        rarity.textContent = itemData.rarity.toUpperCase();
        rarity.style.color = this.rarityColors[itemData.rarity];
        
        content.appendChild(icon);
        content.appendChild(label);
        content.appendChild(rarity);
        item.appendChild(content);
        
        return item;
    }

    getItemImageUrl(itemName) {
        return this.inventoryConfig.iconPath + itemName + this.inventoryConfig.iconExtension;
    }

    getItemIcon(itemName) {
        const icons = {
            bread: '🍞',
            'ammo-9': '📦',
            money: '💰'
        };
        
        return icons[itemName] || '📦';
    }

    startSpin() {
        console.log('Starting spin animation');
        this.isSpinning = true;
        this.skipBtn.classList.remove('hidden');
        
        // Ensure result container is hidden
        this.resultContainer.classList.add('hidden');
        this.resultContainer.classList.remove('show');
        
        // Play opening sound
        this.playSound('common');
        
        // NEW APPROACH: Let animation determine the winner
        // Instead of trying to sync animation with pre-selected item,
        // we'll let the animation land randomly and use whatever it lands on
        
        const targetIndex = 44; // We still target index 44 for consistency
        
        // Get the actual computed style values
        const firstItem = this.spinner.children[0];
        if (!firstItem) {
            console.error('No spinner items found!');
            return;
        }
        
        const computedStyle = window.getComputedStyle(firstItem);
        const itemWidth = parseFloat(computedStyle.flexBasis) || 150;
        const marginLeft = parseFloat(computedStyle.marginLeft) || 10;
        const marginRight = parseFloat(computedStyle.marginRight) || 10;
        const totalItemWidth = itemWidth + marginLeft + marginRight;
        
        // Add some randomness to where we land (within a few items of target)
        const randomOffset = (Math.random() - 0.5) * 3; // ±1.5 items of randomness
        const actualTargetIndex = Math.round(targetIndex + randomOffset);
        
        // Calculate position to center the actual target
        const itemPositionFromLeft = actualTargetIndex * totalItemWidth;
        const viewportCenter = this.spinner.parentElement.offsetWidth / 2;
        const distanceToCenter = itemPositionFromLeft - viewportCenter + (totalItemWidth / 2);
        
        // Add spinning effect
        const extraSpins = totalItemWidth * (8 + Math.random() * 4); // 8-12 spins
        const finalPosition = -(distanceToCenter + extraSpins);
        
        // Store what we expect to land on for verification
        this.expectedLandingIndex = actualTargetIndex;
        
        console.log('=== NEW APPROACH: ANIMATION DETERMINES WINNER ===');
        console.log('Original target index:', targetIndex);
        console.log('Random offset:', randomOffset);
        console.log('Actual target index:', actualTargetIndex);
        console.log('Total item width:', totalItemWidth, 'px');
        console.log('Distance to center:', distanceToCenter, 'px');
        console.log('Extra spins:', extraSpins, 'px');
        console.log('Final position:', finalPosition, 'px');
        console.log('Expected landing item:', this.spinnerItems[actualTargetIndex]);
        console.log('================================================');
        
        // Apply spinning animation
        this.spinner.style.transition = 'transform 4s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
        this.spinner.style.transform = `translateX(${finalPosition}px)`;
        
        // Stop spinning after animation
        this.spinTimeout = setTimeout(() => {
            this.stopSpin();
        }, 4000);
    }

    stopSpin() {
        console.log('Animation finished - stopping spin');
        this.isSpinning = false;
        this.skipBtn.classList.add('hidden');
        
        // Visual verification: check which item is actually in the center now
        this.verifyAlignment();
        
        // Play reward sound
        this.playSound(this.selectedReward.rarity);
        
        // Show result
        this.showResult();
    }

    verifyAlignment() {
        const transform = this.spinner.style.transform;
        const translateX = parseFloat(transform.match(/translateX\(([^)]+)px\)/)?.[1] || 0);
        
        const firstItem = this.spinner.children[0];
        if (!firstItem) return;
        
        const computedStyle = window.getComputedStyle(firstItem);
        const itemWidth = parseFloat(computedStyle.flexBasis) || 150;
        const marginLeft = parseFloat(computedStyle.marginLeft) || 10;
        const marginRight = parseFloat(computedStyle.marginRight) || 10;
        const totalItemWidth = itemWidth + marginLeft + marginRight;
        
        const viewportCenter = this.spinner.parentElement.offsetWidth / 2;
        
        const absoluteCenter = viewportCenter - translateX;
        const centeredItemIndex = Math.round(absoluteCenter / totalItemWidth);
        
        const actualIndex = Math.max(0, Math.min(centeredItemIndex, this.spinnerItems.length - 1));
        const actualWinningItem = this.spinnerItems[actualIndex];
        
        console.log('detecting actual winner');
        console.log('final translateX:', translateX, 'px');
        console.log('viewport center:', viewportCenter, 'px');
        console.log('absolute center position:', absoluteCenter, 'px');
        console.log('calculated centered item index:', centeredItemIndex);
        console.log('clamped actual index:', actualIndex);
        console.log('actual winning item:', actualWinningItem);
        console.log('expected index:', this.expectedLandingIndex);
        
        if (actualWinningItem) {
            console.log('updating winner - replacing pre selected reward with actual landing item');
            console.log('old selected reward:', this.selectedReward);
            
            this.selectedReward = {
                item: actualWinningItem.item,
                label: actualWinningItem.label,
                rarity: actualWinningItem.rarity,
                amount: this.selectedReward.amount
            };
            
            console.log('new selected reward:', this.selectedReward);
        }
    }

    skipAnimation() {
        if (!this.isSpinning) return;
        
        console.log('Skipping animation - jumping to result');
        
        // Clear timeout
        if (this.spinTimeout) {
            clearTimeout(this.spinTimeout);
            this.spinTimeout = null;
        }
        
        // Stop spinning immediately
        this.isSpinning = false;
        this.skipBtn.classList.add('hidden');
        
        // Reset spinner position instantly
        this.spinner.style.transition = 'none';
        this.spinner.style.transform = 'translateX(0)';
        
        // Play reward sound
        this.playSound(this.selectedReward.rarity);
        
        // Show result immediately
        this.showResult();
    }

    showResult() {
        console.log('=== RESULT DISPLAY ===');
        console.log('Selected reward (what we should show):', {
            item: this.selectedReward.item,
            label: this.selectedReward.label,
            rarity: this.selectedReward.rarity,
            amount: this.selectedReward.amount
        });
        console.log('Item at winning position (index 44):', {
            item: this.spinnerItems[44]?.item,
            label: this.spinnerItems[44]?.label,
            rarity: this.spinnerItems[44]?.rarity
        });
        
        // Verify the winning item matches the selected reward
        const winningItem = this.spinnerItems[44];
        if (winningItem && winningItem.item !== this.selectedReward.item) {
            console.warn('⚠️ MISMATCH DETECTED!');
            console.warn('Winning position has:', winningItem.item, winningItem.label);
            console.warn('But selected reward is:', this.selectedReward.item, this.selectedReward.label);
        } else {
            console.log('✅ Items match correctly!');
        }
        console.log('=====================');
        
        // Populate result container
        const resultIcon = document.getElementById('result-icon');
        const resultName = document.getElementById('result-name');
        const resultRarity = document.getElementById('result-rarity');
        const resultAmount = document.getElementById('result-amount');
        
        // Clear previous content
        resultIcon.innerHTML = '';
        
        // Create image for result
        const img = document.createElement('img');
        img.src = this.getItemImageUrl(this.selectedReward.item);
        img.alt = this.selectedReward.label;
        img.onerror = () => {
            // Fallback to placeholder on error
            img.src = this.inventoryConfig.fallbackIcon;
        };
        
        resultIcon.appendChild(img);
        resultName.textContent = this.selectedReward.label;
        resultRarity.textContent = this.selectedReward.rarity.toUpperCase();
        resultRarity.style.color = this.rarityColors[this.selectedReward.rarity];
        
        if (resultAmount && this.selectedReward.amount) {
            resultAmount.textContent = 'x' + this.selectedReward.amount;
        }
        
        // Remove hidden class and add show class
        this.resultContainer.classList.remove('hidden');
        this.resultContainer.classList.add('show');
        
        console.log('Result container should now be visible');
    }

    collectReward() {
        console.log('collecting animation determined reward:', this.selectedReward);
        
        if (!this.isOpen) {
            return;
        }
        
        fetch(`https://${GetParentResourceName()}/collectReward`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                actualWinner: this.selectedReward
            })
        }).catch(() => {});
        
        this.isOpen = false;
        this.isSpinning = false;
        
        if (this.spinTimeout) {
            clearTimeout(this.spinTimeout);
            this.spinTimeout = null;
        }
        
        // Hide container
        this.container.style.display = 'none';
        this.container.style.visibility = 'hidden';
        this.container.classList.add('hidden');
        
        // Reset elements
        this.skipBtn.classList.add('hidden');
        this.resultContainer.classList.add('hidden');
        this.resultContainer.classList.remove('show');
        this.spinner.style.transform = 'translateX(0)';
        this.spinner.style.transition = '';
    }

    emergencyClose() {
        console.log('EMERGENCY CLOSE - Clearing everything');
        
        // Prevent multiple calls
        if (!this.isOpen) {
            return;
        }
        
        // Set all states
        this.isOpen = false;
        this.isSpinning = false;
        
        // Clear timeouts
        if (this.spinTimeout) {
            clearTimeout(this.spinTimeout);
            this.spinTimeout = null;
        }
        
        // Hide container multiple ways
        this.container.style.display = 'none';
        this.container.style.visibility = 'hidden';
        this.container.classList.add('hidden');
        
        // Reset elements
        this.skipBtn.classList.add('hidden');
        this.resultContainer.classList.add('hidden');
        this.resultContainer.classList.remove('show');
        this.spinner.style.transform = 'translateX(0)';
        this.spinner.style.transition = '';
        
        // Send force close to client only once
        fetch(`https://${GetParentResourceName()}/forceCloseUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(() => {}); // Ignore fetch errors
    }

    playSound(rarity) {
        // Send sound request to client
        fetch(`https://${GetParentResourceName()}/playSound`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ rarity: rarity })
        });
    }
}

// Global instance
let csgoLootBox;

// Initialize when DOM loads
document.addEventListener('DOMContentLoaded', () => {
    csgoLootBox = new CSGOLootBox();
    console.log('CSGO Loot Box UI initialized');
});

// Listen for messages from client
window.addEventListener('message', (event) => {
    const data = event.data;
    console.log('Received message:', data.type);
    
    switch (data.type) {
        case 'openLootBox':
            if (csgoLootBox) {
                csgoLootBox.open(data.spinnerItems, data.selectedReward);
            }
            break;
            
        case 'updateConfig':
            if (csgoLootBox && data.config) {
                csgoLootBox.updateConfig(data.config);
            }
            break;
            
        case 'forceClose':
        case 'close':
            if (csgoLootBox) {
                csgoLootBox.emergencyClose();
            }
            break;
    }
});

// Emergency global close function
window.forceCloseUI = () => {
    if (csgoLootBox) {
        csgoLootBox.emergencyClose();
    }
};
