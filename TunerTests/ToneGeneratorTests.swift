// TunerTests/ToneGeneratorTests.swift
import XCTest
import AVFoundation
@testable import Tuner

final class ToneGeneratorTests: XCTestCase {
    func testGeneratesBufferWithCorrectFrameCount() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        // 0.03s * 44100 = 1323 frames
        XCTAssertEqual(Int(buffer.frameLength), 1323)
    }

    func testGeneratesNonSilentBuffer() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        let channelData = buffer.floatChannelData![0]
        let maxAmplitude = (0..<Int(buffer.frameLength)).map { abs(channelData[$0]) }.max() ?? 0
        XCTAssertGreaterThan(maxAmplitude, 0.1)
    }

    func testEnvelopeStartsNearZero() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        let channelData = buffer.floatChannelData![0]
        XCTAssertLessThan(abs(channelData[0]), 0.01)
    }

    func testEnvelopeEndsNearZero() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 880, duration: 0.03, sampleRate: 44100)
        let channelData = buffer.floatChannelData![0]
        let lastSample = channelData[Int(buffer.frameLength) - 1]
        XCTAssertLessThan(abs(lastSample), 0.05)
    }

    func testBufferFormatIsMono44100() {
        let buffer = ToneGenerator.makeClickBuffer(frequency: 660, duration: 0.03, sampleRate: 44100)
        XCTAssertEqual(buffer.format.channelCount, 1)
        XCTAssertEqual(buffer.format.sampleRate, 44100)
    }
}
