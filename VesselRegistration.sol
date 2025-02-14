// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VesselRegistration
 * @dev Stores and verifies the registration details of vessels (by IMO number).
 *      Only an admin can add or modify vessel records.
 */
contract VesselRegistration {
    /// @dev Holds basic vessel data: IMO number, owner, and flag state.
    struct Vessel {
        string imoNumber;
        string owner;
        string flagState;
    }

    /// @notice Mapping of IMO number -> Vessel details.
    mapping(string => Vessel) private vessels;

    /// @notice Address of the contract administrator (e.g., maritime authority).
    address public admin;

    /// @dev Restricts access to admin-only functions.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    /**
     * @dev Initializes the contract, setting the deployer as `admin`.
     */
    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Registers a new vessel.
     * @param imoNumber The unique IMO number for the vessel.
     * @param owner The owner or operator's identifier.
     * @param flagState The vessel's flag state (e.g., country code).
     */
    function registerVessel(
        string memory imoNumber,
        string memory owner,
        string memory flagState
    ) public onlyAdmin {
        vessels[imoNumber] = Vessel(imoNumber, owner, flagState);
    }

    /**
     * @notice Checks if a vessel is registered by IMO number.
     * @param imoNumber The IMO number to query.
     * @return True if the vessel is registered, false otherwise.
     */
    function isVesselRegistered(string calldata imoNumber)
        external
        view
        returns (bool)
    {
        return bytes(vessels[imoNumber].imoNumber).length > 0;
    }

    /**
     * @notice Retrieves the flag state of a given vessel.
     * @param imoNumber The IMO number of the vessel.
     * @return The flag state as a string.
     */
    function getFlagState(string calldata imoNumber)
        external
        view
        returns (string memory)
    {
        return vessels[imoNumber].flagState;
    }
}
