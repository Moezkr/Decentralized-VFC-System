// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract VFC {
    address admin;
    
    struct Customer {
        string userName;
        string data;
        bool VFCStatus;
        uint256 rating;
        uint256 upvotes;
        address bank;
    }

    struct Bank {
        string name;
        address ethAddress;
        uint256 rating;
        uint256 VFC_count;
        string regNumber;
    }

    struct VFCRequest {
        string userName;
        address bank;
        string data;
        bool isAllowed;
    }

    mapping(string => Customer) customers;
    string[] customerNames;

    mapping(string => Customer) final_customers;
    string[] final_customerNames;

    mapping(address => Bank) banks;
    address[] bankAddresses;

    mapping(string => VFCRequest) VFCRequests;
    string[] customerDataList;

    mapping(string => mapping(address => uint256)) upvotes;

    constructor() {
        admin = msg.sender;
    }

    function addVFCRequest(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (msg.sender == bankAddresses[i]) {
                require(
                    !(VFCRequests[_customerData].bank == msg.sender),
                    "This user already has a VFC request with same data in process."
                );
                VFCRequests[_customerData].data = _customerData;
                VFCRequests[_customerData].userName = _userName;
                VFCRequests[_customerData].bank = msg.sender;

                banks[msg.sender].VFC_count++;

                if (banks[msg.sender].rating <= 50) {
                    VFCRequests[_customerData].isAllowed = false;
                } else {
                    VFCRequests[_customerData].isAllowed = true;
                }
                customerDataList.push(_customerData);
                return 1;
            }
        }
        return 0; 
    }

    function addCustomer(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (msg.sender == bankAddresses[i]) {
                for (uint256 k = 0; k < customerDataList.length; k++) {
                    if (stringsEquals(customerDataList[k], _customerData)) {
                        require(
                            customers[_userName].bank == address(0),
                            "This customer is already present, modifyCustomer to edit the customer data"
                        );
                        require(
                            VFCRequests[_customerData].isAllowed == true,
                            "isAllowed is false, bank is not trusted to perform the transaction"
                        );
                        customers[_userName].userName = _userName;
                        customers[_userName].data = _customerData;
                        customers[_userName].bank = msg.sender;
                        customers[_userName].upvotes = 0;
                        customerNames.push(_userName);
                        return 1;
                    }
                }
            }
        }
        return 0; 
    }

    function removeVFCRequest(
        string memory _userName,
        string memory customerData
    ) public returns (uint8) {
        require(
            (stringsEquals(VFCRequests[customerData].userName, _userName)),
            "Please enter valid UserName and Customer Data Hash"
        );

        for (uint256 i = 0; i < customerDataList.length; i++) {
            if (stringsEquals(customerDataList[i], customerData)) {
                delete VFCRequests[customerData];
                for (uint256 j = i + 1; j < customerDataList.length; j++) {
                    customerDataList[j - 1] = customerDataList[j];
                }
                customerDataList.pop(); // Fixes the missing array length adjustment
                return 1;
            }
        }
        return 0; 
    }

    function removeCustomer(string memory _userName) public returns (uint8) {
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                delete customers[_userName];
                for (uint256 j = i + 1; j < customerNames.length; j++) {
                    customerNames[j - 1] = customerNames[j];
                }
                customerNames.pop(); // Fixes the missing array length adjustment
                return 1;
            }
        }
        return 0;
    }

    function viewCustomer(string memory _userName)
        public
        view
        returns (
            string memory,
            string memory,
            address
        )
    {
        require(
            customers[_userName].bank != address(0),
            "Customer is not present in the database"
        );
        return (
            customers[_userName].userName,
            customers[_userName].data,
            customers[_userName].bank
        );
    }

    function modifyCustomer(
        string memory _userName,
        string memory _newcustomerData
    ) public {
        require(
            customers[_userName].bank != address(0),
            "Customer is not present in the database"
        );
        customers[_userName].data = _newcustomerData;
    }

    string[] VFC_UnValidatedCount;

    function getBankRequest(address bankAddress, uint256 index)
        public
        returns (
            string memory,
            string memory,
            address,
            bool
        )
    {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == bankAddress) {
                for (uint256 k = 0; k < customerDataList.length; k++) {
                    if (
                        (VFCRequests[customerDataList[k]].bank ==
                            bankAddress) &&
                        (VFCRequests[customerDataList[k]].isAllowed == false)
                    ) {
                        VFC_UnValidatedCount.push(customerDataList[k]);
                    }
                }
            }
        }
        return (
            VFCRequests[VFC_UnValidatedCount[index]].userName,
            VFCRequests[VFC_UnValidatedCount[index]].data,
            VFCRequests[VFC_UnValidatedCount[index]].bank,
            VFCRequests[VFC_UnValidatedCount[index]].isAllowed
        );
    }

    mapping(address => mapping(address => uint256)) upvotesBank;
    mapping(address => uint256) upvoteCount;

    function upvoteBank(address bankAddress) public returns (uint8) {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (msg.sender == bankAddresses[i]) {
                require(
                    upvotesBank[bankAddress][msg.sender] == 0,
                    "You have already upvoted this bank"
                );
                upvotesBank[bankAddress][msg.sender] = 1;
                upvoteCount[bankAddress]++;
                banks[bankAddress].rating =
                    (upvoteCount[bankAddress] * 100) /
                    bankAddresses.length;

                return 1;
            }
        }
        return 0;
    }

    function getCustomerRating(string memory userName)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], userName))
                return customers[userName].rating;
        }
        return 0; // Return a default value if the customer is not found
    }

    function getBankRating(address bankAddress) public view returns (uint256) {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == bankAddress) {
                return banks[bankAddress].rating;
            }
        }
        return 0; // Return a default value if the bank is not found
    }

    function upvoteCustomer(string memory _userName) public returns (uint8) {
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                require(
                    upvotes[_userName][msg.sender] == 0,
                    "This bank has already upvoted this customer"
                );
                upvotes[_userName][msg.sender] = 1; 
                customers[_userName].upvotes++;

                customers[_userName].rating =
                    (customers[_userName].upvotes * 100) /
                    bankAddresses.length;

                if (customers[_userName].rating > 50) {
                    final_customers[_userName].userName = _userName;
                    final_customers[_userName].data = customers[_userName].data;
                    final_customers[_userName].rating = customers[_userName]
                        .rating;
                    final_customers[_userName].upvotes = customers[_userName]
                        .upvotes;
                    final_customers[_userName].bank = customers[_userName].bank;
                    final_customerNames.push(_userName);
                }

                return 1;
            }
        }
        return 0;
    }

    function getBankDetail(address bankAddress)
        public
        view
        returns (
            string memory,
            address,
            uint256,
            uint256,
            string memory
        )
    {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == bankAddress) {
                return (
                    banks[bankAddress].name,
                    banks[bankAddress].ethAddress,
                    banks[bankAddress].rating,
                    banks[bankAddress].VFC_count,
                    banks[bankAddress].regNumber
                );
            }
        }
        return ("", address(0), 0, 0, "");
    }

    function addBank(
        string memory _name,
        address _bankAddress,
        string memory _regNumber
    ) public {
        require(msg.sender == admin, "You are not authorized");
        banks[_bankAddress].name = _name;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].rating = 1;
        banks[_bankAddress].VFC_count = 0;
        banks[_bankAddress].regNumber = _regNumber;
        bankAddresses.push(_bankAddress);
    }

    function stringsEquals(string memory s1, string memory s2)
        private
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
