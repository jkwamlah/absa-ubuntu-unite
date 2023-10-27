// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RewardsSystem {
	address public owner;

	struct Account {
		string name;
		uint256 number;
		uint256 passcode;
		string status;
		uint256 balance;
	}

	struct TransactionCategory {
		uint256 id;
		string action;
		uint256 points;
		uint256 threshold;
	}

	struct Badge {
		uint256 id;
		string name;
		string description;
		uint256 points;
	}

	Badge[] public badges;
	Account[] public accounts;
	TransactionCategory[] public transactionCategories;
	mapping(uint256 => mapping(string => mapping(string => uint256))) public rewards;
	mapping(uint256 => mapping(uint256 => bool)) public unlockedBadges;

	event AccountCreated(string name, uint256 number, uint256 passcode, uint256 balance, string status);
	event TransactionCategoryCreated(uint256 id, string action, uint256 points, uint256 threshold, uint256 timestamp);
	event BadgeCreated(uint256 id, string name, string description, uint256 points);
	event BadgeUnlocked(uint256 account, uint256 badgeId, uint256 timestamp);

	modifier isOwner() {
		require(msg.sender == owner, "Only the owner can perform this action");
		_;
	}

	modifier accountExist(uint256 _number) {
		for (uint256 i = 0; i < accounts.length; i++) {
			require(accounts[i].number != _number, "Account already exists");
		}
		_;
	}

	modifier badgeExist(string memory _name) {
		for (uint256 i = 0; i < badges.length; i++) {
			require(keccak256(bytes(badges[i].name)) != keccak256(bytes(_name)), "Badge already exist!");
		}
		_;
	}

	modifier transactionCategoryDoesNotExist(string memory _action) {
		for (uint256 i = 0; i < transactionCategories.length; i++) {
			require(
				keccak256(bytes(transactionCategories[i].action)) != keccak256(bytes(_action)),
				"Category already exists"
			);
		}
		_;
	}

	constructor() {
		owner = msg.sender;
	}

	function createAccount(string memory _name, uint256 _number, uint256 _passcode) public isOwner accountExist(_number) {
		require(bytes(_name).length > 0, "Name cannot be empty!");
		require(_number > 0, "Number cannot be empty!");

		Account memory _account = Account({
		name: _name,
		number: _number,
		passcode: _passcode,
		balance: 0,
		status: 'pending'
		});

		accounts.push(_account);
		emit AccountCreated(_name, _number, _passcode, _account.balance, _account.status);
	}

	function createBadge(string memory _name, string memory _description, uint256 _points) public isOwner badgeExist(_name){
		require(bytes(_name).length > 0, "Name cannot be empty!");
		require(bytes(_description).length > 0, "Description cannot be empty!");

		uint256 badgeSize = badges.length;
		uint256 badgeId = badgeSize + 1;

		Badge memory _badge = Badge({
		id: badgeId,
		name: _name,
		description: _description,
		points: _points
		});

		badges.push(_badge);
		emit BadgeCreated(badgeId, _name, _description, _points);
	}

	function createTransactionCategory(string memory _action, uint256 _points, uint256 _threshold) public isOwner transactionCategoryDoesNotExist(_action) {
		require(bytes(_action).length > 0, "Action cannot be empty!");
		require(_points > 0, "Points cannot be empty!");
		require(_threshold > 0, "Threshold cannot be empty!");

		uint256 transactionCategorySize = transactionCategories.length;
		uint256 categoryId = transactionCategorySize + 1;
		transactionCategories.push(TransactionCategory({
		id: categoryId,
		action: _action,
		points: _points,
		threshold: _threshold
		}));

		emit TransactionCategoryCreated(categoryId, _action, _points, _threshold, block.timestamp);
	}

	function earnRewards(string memory _action, uint256 _account, string memory _date) public isOwner {
		require(bytes(_action).length > 0, "Action cannot be empty!");
		require(_account > 0, "Account cannot be empty!");
		require(bytes(_date).length > 0, "Date cannot be empty!");

		Account memory account;
		bool accountFound = false;
		for (uint256 i = 0; i < accounts.length; i++) {
			if (accounts[i].number == _account) {
				account = accounts[i];
				accountFound = true;
				break;
			}
		}
		require(accountFound, "Account not found!");

		TransactionCategory memory category;
		bool categoryFound = false;
		for (uint256 i = 0; i < transactionCategories.length; i++) {
			if (keccak256(bytes(transactionCategories[i].action)) == keccak256(bytes(_action))) {
				category = transactionCategories[i];
				categoryFound = true;
				break;
			}
		}
		require(categoryFound, "Transaction category does not exist!");

		uint256 userPointsByDay = getPointsByDate(_account, _date, _action);
		updateUserRewards(_account, _date, category.action, category.points, category.threshold, userPointsByDay);
	}

	function getPointsByDate(
		uint _account,
		string memory _date,
		string memory _action
	) public view returns (uint256) {
		return rewards[_account][_date][_action];
	}

	function updateUserRewards(
		uint _account,
		string memory _date,
		string memory _action,
		uint256 _categoryPoints,
		uint256 _threshold,
		uint _userPoints
	) private {
		require(_userPoints + _categoryPoints <= _threshold, "Threshold reached!");

		rewards[_account][_date][_action] += _categoryPoints;
		uint256 userAccountBalance = 0;
		for (uint256 i = 0; i < accounts.length; i++) {
			if (accounts[i].number == _account) {
				accounts[i].balance += _categoryPoints;
				userAccountBalance = accounts[i].balance;
				break;
			}
		}

		unlockBadgeIfThresholdMet(_account, userAccountBalance);
	}

	function unlockBadgeIfThresholdMet(uint256 _account, uint256 _userAccountBalance) private {
		require(_account > 0, "Account cannot be empty");

		for (uint256 i = 0; i < badges.length; i++) {
			if (_userAccountBalance > badges[i].points && !unlockedBadges[_account][badges[i].id]){
				unlockBadge(_account, badges[i].id);
				break;
			}
		}
	}

	function unlockBadge(uint256 _account, uint256 _badgeId) private {
		require(_account > 0, "Account cannot be empty");
		require(_badgeId > 0, "Badge ID cannot be empty");
		unlockedBadges[_account][_badgeId] = true;
		emit BadgeUnlocked(_account, _badgeId, block.timestamp);
	}

	function getAccounts() public view returns (Account[] memory) {
		return accounts;
	}

	function getBadges() public view returns (Badge[] memory) {
		return badges;
	}

}