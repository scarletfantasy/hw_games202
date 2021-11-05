#include "denoiser.h"

Denoiser::Denoiser() : m_useTemportal(false) {}

void Denoiser::Reprojection(const FrameInfo &frameInfo) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    Matrix4x4 preWorldToScreen =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 1];
    Matrix4x4 preWorldToCamera =
        m_preFrameInfo.m_matrix[m_preFrameInfo.m_matrix.size() - 2];
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            m_misc(x, y) = Float3(0.f);
            // TODO: Reproject
            auto position = frameInfo.m_position(x, y);
            auto id = frameInfo.m_id(x, y);
            if (id==-1) {
                continue;
            }
            //auto errortype = Float3::Point;
            auto prelocal2world = m_preFrameInfo.m_matrix[id];
            auto local2world = frameInfo.m_matrix[id];
            auto screenpos = preWorldToScreen(
                (prelocal2world(
                    Inverse(local2world)(position, Float3::EType::Point),
                                Float3::EType::Point)),
                Float3::EType::Point)
                ;
            if (screenpos.x<0||screenpos.x>=width||screenpos.y<0||screenpos.y>=height) {
                m_valid(x,y) = false;
            } else if (m_preFrameInfo.m_id(screenpos.x, screenpos.y) != frameInfo.m_id(x, y)) {
                m_valid(x, y) = false;
            } else {
                m_valid(x, y) = true;
                m_misc(x, y) = m_accColor(screenpos.x, screenpos.y);

            }
            

            //m_valid(x, y) = false;
            
        }
    }
    std::swap(m_misc, m_accColor);
}

void Denoiser::TemporalAccumulation(const Buffer2D<Float3> &curFilteredColor) {
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    int kernelRadius = 3;
    int scount = 0;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Temporal clamp
            int xbegin = std::max(x - 3, 0);
            int xend = std::min(x + 3, width - 1);
            int ybegin = std::max(y - 3, 0);
            int yend = std::min(y + 3, height - 1);
            int count=0;
            Float3 sumcolor = Float3(0.f);
            for (int cx = xbegin; cx <= xend; ++cx) {
                for (int cy = ybegin; cy <= yend; ++cy) {
                    sumcolor += curFilteredColor(cx, cy);
                    ++count;
                }
            }
            auto avg = sumcolor / count;
            Float3 sigma=Float3(0.0f);
            for (int cx = xbegin; cx <= xend; ++cx) {
                for (int cy = ybegin; cy <= yend; ++cy) {
                    auto curcolor = curFilteredColor(cx, cy);
                    sigma += curcolor * curcolor / count;
                }
            }
            

            Float3 color = m_accColor(x, y);
            //color = Clamp(color, avg - sigma * m_colorBoxK, avg + sigma * m_colorBoxK);
            // TODO: Exponential moving average
            float alpha = 1.0f;
            if (m_valid(x,y)) {
                alpha = m_alpha;
                
            }
            m_misc(x, y) = Lerp(color, curFilteredColor(x, y), alpha);
            
        }
    }
    
    std::swap(m_misc, m_accColor);
}

Buffer2D<Float3> Denoiser::Filter(const FrameInfo &frameInfo) {
    int height = frameInfo.m_beauty.m_height;
    int width = frameInfo.m_beauty.m_width;
    Buffer2D<Float3> filteredImage = CreateBuffer2D<Float3>(width, height);
    int kernelRadius = 16;
#pragma omp parallel for
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // TODO: Joint bilateral filter
            int xbegin = std::max(x - kernelRadius, 0);
            int xend = std::min(x + kernelRadius, width-1);
            int ybegin = std::max(y - kernelRadius, 0);
            int yend = std::min(y + kernelRadius, height - 1);
            auto depth = frameInfo.m_depth(x, y);
            auto normal = frameInfo.m_normal(x, y);
            auto color = frameInfo.m_beauty(x, y);
            auto position = frameInfo.m_position(x, y);
            float weightsum = 0.0;
            Float3 rescolor = Float3(0.f);
            for (int cx=xbegin;cx<=xend;++cx) 
            {
                for (int cy = ybegin; cy <= yend; ++cy) 
                {
                    if ((cx==x)&&(cy==y)) {
                        weightsum += 1.0f;
                        rescolor += color;
                    } 
                    else 
                    {
                        auto cdepth = frameInfo.m_depth(cx, cy);
                        auto cnormal = frameInfo.m_normal(cx, cy);
                        auto ccolor = frameInfo.m_beauty(cx, cy);
                        auto cposition = frameInfo.m_position(cx, cy);
                        auto dnormal = SafeAcos(Dot(normal, cnormal));
                        auto dplane = Dot(normal, (position - cposition) /
                                                      (Distance(position, cposition)+0.0001f));
                        auto dcolor2 = SqrDistance(color, ccolor);
                        auto weight = exp(-((cx - x) * (cx - x) + (cy - y) * (cy - y)) /
                                              2.0f / m_sigmaCoord -
                                          dcolor2 / 2.0f / m_sigmaColor -
                                          dnormal * dnormal / 2.0f / m_sigmaNormal -
                                          dplane * dplane / 2.0f / m_sigmaPlane);
                        rescolor += ccolor * weight;
                        weightsum += weight;
                    }
                    
                }
            }
            if (weightsum!=0.0f)
                rescolor /= weightsum;

            //filteredImage(x, y) = frameInfo.m_beauty(x, y);
            filteredImage(x, y) = rescolor;
        }
    }
    return filteredImage;
}

void Denoiser::Init(const FrameInfo &frameInfo, const Buffer2D<Float3> &filteredColor) {
    m_accColor.Copy(filteredColor);
    int height = m_accColor.m_height;
    int width = m_accColor.m_width;
    m_misc = CreateBuffer2D<Float3>(width, height);
    m_valid = CreateBuffer2D<bool>(width, height);
}

void Denoiser::Maintain(const FrameInfo &frameInfo) { m_preFrameInfo = frameInfo; }

Buffer2D<Float3> Denoiser::ProcessFrame(const FrameInfo &frameInfo) {
    // Filter current frame
    Buffer2D<Float3> filteredColor;
    filteredColor = Filter(frameInfo);

    // Reproject previous frame color to current
    if (m_useTemportal) {
        Reprojection(frameInfo);
        TemporalAccumulation(filteredColor);
    } else {
        Init(frameInfo, filteredColor);
    }

    // Maintain
    Maintain(frameInfo);
    if (!m_useTemportal) {
        m_useTemportal = true;
    }
    return m_accColor;
}
