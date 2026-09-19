package com.taskmanager.auth.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class JwtServiceTest {

    private static final String SECRET = "unit-test-secret-0123456789abcdef-test-secret-xx";
    private static final long EXPIRATION_MS = 60_000;

    private final JwtService jwtService = new JwtService(SECRET, EXPIRATION_MS);

    @Test
    void generatesTokenThatRoundTrips() {
        String token = jwtService.generateToken(42L, "user@example.com");

        assertThat(token).isNotBlank();
        assertThat(jwtService.extractEmail(token)).isEqualTo("user@example.com");
        assertThat(jwtService.extractUserId(token)).isEqualTo(42L);
        assertThat(jwtService.isTokenValid(token, "user@example.com")).isTrue();
    }

    @Test
    void returnsFalseForTokenSignedForAnotherUser() {
        String token = jwtService.generateToken(42L, "user@example.com");

        assertThat(jwtService.isTokenValid(token, "other@example.com")).isFalse();
    }

    @Test
    void rejectsGarbageToken() {
        assertThat(jwtService.isTokenValid("not.a.jwt", "user@example.com")).isFalse();
    }

    @Test
    void rejectsTokenFromDifferentSecret() {
        JwtService other = new JwtService(SECRET + "-different", EXPIRATION_MS);
        String token = other.generateToken(1L, "user@example.com");

        assertThat(jwtService.isTokenValid(token, "user@example.com")).isFalse();
    }

    @Test
    void rejectsSecretShorterThan256Bits() {
        assertThatThrownBy(() -> new JwtService("too-short", EXPIRATION_MS))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("32 bytes");
    }

    @Test
    void rejectsBlankSecret() {
        assertThatThrownBy(() -> new JwtService("   ", EXPIRATION_MS))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("JWT_SECRET");
    }
}